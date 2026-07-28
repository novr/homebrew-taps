#!/usr/bin/env ruby
# frozen_string_literal: true

require "erb"

FORMULA_NAME_PATTERN = /\A[a-z0-9-]+\z/
BINARY_NAME_PATTERN = /\A[a-z0-9_-]+\z/
LICENSE_PATTERN = /\A[A-Za-z0-9.+()-]+\z/
SHA256_PATTERN = /\A[a-f0-9]{64}\z/i
SOURCE_REPO_PATTERN = /\Anovr\/[A-Za-z0-9._-]+\z/
SERVICE_CONFIG_PATTERN = /\A[a-z0-9][a-z0-9._-]*(?:\/[a-z0-9][a-z0-9._-]*)+\z/
SERVICE_RUN_ARG_PATTERN = /\A-{0,2}[a-zA-Z0-9][a-zA-Z0-9._-]*\z/
SERVICE_CONFIG_SOURCE_PATTERN = %r{\A[a-z0-9][a-z0-9._/-]*\z}
COMPLETION_SHELL_PATTERN = /\A(bash|zsh|fish|pwsh)\z/
COMPLETION_FORMAT_PATTERN = /\A(cobra|clap|click|arg|flag|typer|none)\z/
COMPLETION_ARG_PATTERN = SERVICE_RUN_ARG_PATTERN
# dispatch 元を novr org に限定する（tap の信頼境界）
NOVR_GITHUB_URL_PATTERN = %r{\Ahttps://github\.com/novr/}i
MACOS_URL_SHA256_PATTERN = /(on_macos do\n\s+url )"[^"]+"\n(\s+sha256 )"[^"]+"/m
# universal 化前の Formula を壊さず移行する
LEGACY_MACOS_ARM_PATTERN = /on_macos do\n\s+on_arm do\n\s+url "[^"]+"\n\s+sha256 "[^"]+"\n\s+end\n\s+end/m

def formula_path
  name = ENV.fetch("FORMULA")
  abort("Invalid formula name: #{name}") unless name.match?(FORMULA_NAME_PATTERN)

  path = File.expand_path("Formula/#{name}.rb", Dir.pwd)
  formula_dir = File.expand_path("Formula", Dir.pwd)
  abort("Invalid formula path: #{path}") unless path.start_with?("#{formula_dir}/")

  path
end

def class_name
  ENV.fetch("FORMULA").split("-").map(&:capitalize).join
end

def ruby_string(value)
  value.to_s
         .gsub("\\", "\\\\")
         .gsub('"', '\\"')
         .gsub("\n", '\\n')
         .gsub("\r", '\\r')
         .gsub("\t", '\\t')
end

def validate_sha256!(value, label = "sha256")
  abort("Invalid #{label}: #{value}") unless value.match?(SHA256_PATTERN)
end

def validate_novr_url!(value, label = "url")
  abort("URL must be under https://github.com/novr/: #{value}") unless value.match?(NOVR_GITHUB_URL_PATTERN)
end

def validate_binary_name!(value)
  abort("Invalid binary name: #{value}") unless value.match?(BINARY_NAME_PATTERN)
end

def validate_license!(value)
  abort("Invalid license: #{value}") unless value.match?(LICENSE_PATTERN)
end

def validate_service_config!(value)
  return if value.nil? || value.empty?

  abort("Invalid service_config: #{value}") unless value.match?(SERVICE_CONFIG_PATTERN)
  abort("Invalid service_config: #{value}") if value.include?("..")
end

def validate_service_run_args!(value)
  return if value.nil? || value.empty?

  value.split(",").each do |arg|
    abort("Invalid service_run_args: #{value}") if arg.empty?
    abort("Invalid service_run_args: #{value}") unless arg.match?(SERVICE_RUN_ARG_PATTERN)
  end
end

def validate_service_config_source!(value)
  return if value.nil? || value.empty?

  abort("Invalid service_config_source: #{value}") unless value.match?(SERVICE_CONFIG_SOURCE_PATTERN)
  abort("Invalid service_config_source: #{value}") if value.include?("..")
end

def validate_brew_service_fields!
  run_args = ENV["SERVICE_RUN_ARGS"]
  config = ENV["SERVICE_CONFIG"]
  source = ENV["SERVICE_CONFIG_SOURCE"]

  validate_service_run_args!(run_args)
  validate_service_config!(config)
  validate_service_config_source!(source)

  if source && !source.empty?
    abort("service_config is required when service_config_source is set") if config.nil? || config.empty?
  end
end

def validate_completion_shells!(value)
  return if value.nil? || value.empty?

  value.split(",").each do |shell|
    shell = shell.strip
    abort("Invalid completion_shells: #{value}") if shell.empty?
    abort("Invalid completion_shells: #{value}") unless shell.match?(COMPLETION_SHELL_PATTERN)
  end
end

def validate_completion_args!(value)
  return if value.nil? || value.empty?

  value.split(",").each do |arg|
    arg = arg.strip
    abort("Invalid completion_args: #{value}") if arg.empty?
    abort("Invalid completion_args: #{value}") unless arg.match?(COMPLETION_ARG_PATTERN)
  end
end

def validate_completion_format!(value)
  return if value.nil? || value.empty?

  abort("Invalid completion_format: #{value}") unless value.match?(COMPLETION_FORMAT_PATTERN)
end

def validate_completion_fields!
  shells = ENV["COMPLETION_SHELLS"]
  args = ENV["COMPLETION_ARGS"]
  format = ENV["COMPLETION_FORMAT"]

  validate_completion_shells!(shells)
  validate_completion_args!(args)
  validate_completion_format!(format)

  has_args = args && !args.empty?
  has_format = format && !format.empty?
  has_shells = shells && !shells.empty?

  return unless has_args || has_format

  abort("completion_shells is required when completion_args or completion_format is set") unless has_shells
end

def source_repo
  ENV.fetch("SOURCE_REPO")
end

def validate_source_repo!
  repo = source_repo
  abort("Invalid source_repo: #{repo}") unless repo.match?(SOURCE_REPO_PATTERN)

  homepage = ENV["HOMEPAGE"]
  return if homepage.nil? || homepage.empty?

  expected_homepage = "https://github.com/#{repo}"
  return if homepage.casecmp?(expected_homepage)

  abort("homepage must be #{expected_homepage}")
end

def validate_release_url!(url, label = "url")
  validate_novr_url!(url, label)

  expected_prefix = "https://github.com/#{source_repo}/releases/"
  return if url.downcase.start_with?(expected_prefix.downcase)

  abort("URL must be a release asset for #{source_repo} (#{label}): #{url}")
end

def validate_urls_and_checksums!
  validate_release_url!(ENV.fetch("URL"))
  validate_sha256!(ENV.fetch("SHA256"))
end

def validate_core_metadata!
  validate_source_repo!
  validate_binary_name!(binary)
  validate_license!(license)
end

def validate_metadata!
  validate_core_metadata!
  validate_brew_service_fields!
  validate_completion_fields!
end

def upsert_allowed?
  desc = ENV["DESC"]
  homepage = ENV["HOMEPAGE"]
  desc && !desc.empty? && homepage && !homepage.empty?
end

def macos_block(url, sha256)
  <<~RUBY.chomp
    on_macos do
      url "#{url}"
      sha256 "#{sha256}"
    end
  RUBY
end

def replace_macos_url_sha256!(content, url, sha256)
  if content.match?(MACOS_URL_SHA256_PATTERN)
    return content.sub(MACOS_URL_SHA256_PATTERN, "\\1\"#{url}\"\n\\2\"#{sha256}\"")
  end

  abort("Failed to find on_macos url/sha256 block in #{formula_path}") unless content.match?(LEGACY_MACOS_ARM_PATTERN)

  content.sub(LEGACY_MACOS_ARM_PATTERN, macos_block(url, sha256))
end

def update_version(content)
  unless content.match?(/^\s*version\s+".*"$/)
    abort("Failed to find version in #{formula_path}")
  end

  content.sub(/^\s*version\s+".*"$/, "  version \"#{ruby_string(ENV.fetch("VERSION"))}\"")
end

def update_formula!
  validate_core_metadata!
  validate_urls_and_checksums!

  path = formula_path
  unless File.file?(path)
    return add_formula! if upsert_allowed?

    abort("Formula not found: #{path}")
  end

  content = File.read(path)
  content = update_version(content)
  content = replace_macos_url_sha256!(content, ENV.fetch("URL"), ENV.fetch("SHA256"))

  File.write(path, content)
end

def add_formula!
  validate_metadata!
  validate_urls_and_checksums!
  abort("client_payload.desc is required for add-formula") unless upsert_allowed?

  path = formula_path
  # release 側が add-formula 固定でも既存 Formula を更新できるようにする
  return update_formula! if File.file?(path)

  File.write(path, ERB.new(formula_template, trim_mode: "-").result(binding))
end

def formula_template
  <<~RUBY
    class <%= class_name %> < Formula
      desc "<%= ruby_string(ENV.fetch("DESC")) %>"
      homepage "<%= ruby_string(ENV.fetch("HOMEPAGE")) %>"
      version "<%= ruby_string(ENV.fetch("VERSION")) %>"
      license "<%= ruby_string(license) %>"

      on_macos do
        url "<%= ruby_string(ENV.fetch("URL")) %>"
        sha256 "<%= ruby_string(ENV.fetch("SHA256")) %>"
      end

      def install
<%= install_body %>
      end
<%= service_block %>
      test do
        output = shell_output("\#{bin}/<%= ruby_string(binary) %> --help")
        assert_match "<%= ruby_string(test_match) %>", output
      end
    end
  RUBY
end

def binary
  value = ENV["BINARY"]
  value = ENV.fetch("FORMULA") if value.nil? || value.empty?
  value
end

def license
  value = ENV["LICENSE"]
  value = "MIT" if value.nil? || value.empty?
  value
end

def test_match
  ENV.fetch("TEST_MATCH", "USAGE: #{binary}")
end

def service_config
  value = ENV["SERVICE_CONFIG"]
  return nil if value.nil? || value.empty?

  value
end

def service_config_source
  value = ENV["SERVICE_CONFIG_SOURCE"]
  return nil if value.nil? || value.empty?

  value
end

def service_run_args
  value = ENV["SERVICE_RUN_ARGS"]
  return nil if value.nil? || value.empty?

  value.split(",")
end

def completion_shells
  value = ENV["COMPLETION_SHELLS"]
  return nil if value.nil? || value.empty?

  value.split(",").map(&:strip).reject(&:empty?)
end

def completion_args
  value = ENV["COMPLETION_ARGS"]
  return [] if value.nil? || value.empty?

  value.split(",").map(&:strip).reject(&:empty?)
end

def completion_format
  value = ENV["COMPLETION_FORMAT"]
  return nil if value.nil? || value.empty?

  value
end

def completion_shells?
  shells = completion_shells
  !shells.nil? && !shells.empty?
end

def brew_service?
  !service_run_args.nil?
end

def install_body
  lines = ["        bin.install \"#{ruby_string(binary)}\""]
  if service_config_source
    target = ruby_string(service_config)
    source = ruby_string(service_config_source)
    lines << "        etc.install \"#{source}\" => \"#{target}\" unless (etc/\"#{target}\").exist?"
  elsif service_config
    etc_dir = File.dirname(service_config)
    lines << "        (etc/\"#{ruby_string(etc_dir)}\").mkpath" unless etc_dir == "."
  end
  completion_line = completion_install_line
  lines << completion_line if completion_line
  lines.join("\n")
end

def completion_install_line
  return nil unless completion_shells?

  parts = ["bin/\"#{ruby_string(binary)}\""]
  completion_args.each { |arg| parts << "\"#{ruby_string(arg)}\"" }

  options = ["shells: [#{completion_shells.map { |shell| ":#{shell}" }.join(', ')}]"]
  options << "shell_parameter_format: :#{completion_format}" if completion_format

  "        generate_completions_from_executable(#{parts.join(', ')}, #{options.join(', ')})"
end

def service_run_expression
  parts = ["opt_bin/\"#{ruby_string(binary)}\""]
  service_run_args.each { |arg| parts << "\"#{ruby_string(arg)}\"" }
  parts << "etc/\"#{ruby_string(service_config)}\"" if service_config
  "[#{parts.join(', ')}]"
end

def service_block
  return "" unless brew_service?

  formula = ENV.fetch("FORMULA")
  [
    "",
    "      service do",
    "        run #{service_run_expression}",
    "        keep_alive true",
    "        log_path var/\"log/#{formula}.log\"",
    "        error_log_path var/\"log/#{formula}.error.log\"",
    "        environment_variables PATH: std_service_path_env",
    "      end"
  ].join("\n")
end

case ARGV.fetch(0)
when "update"
  update_formula!
when "add"
  add_formula!
else
  abort("Unknown command: #{ARGV.fetch(0)}")
end
