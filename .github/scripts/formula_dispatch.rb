#!/usr/bin/env ruby
# frozen_string_literal: true

require "erb"

FORMULA_NAME_PATTERN = /\A[a-z0-9-]+\z/
BINARY_NAME_PATTERN = /\A[a-z0-9_-]+\z/
LICENSE_PATTERN = /\A[A-Za-z0-9.+()-]+\z/
SHA256_PATTERN = /\A[a-f0-9]{64}\z/i
SOURCE_REPO_PATTERN = /\Anovr\/[A-Za-z0-9._-]+\z/
NOVR_GITHUB_URL_PATTERN = %r{\Ahttps://github\.com/novr/}i
MULTI_ARCH_FORMULA_PATTERN = /on_intel do\n\s+url "/m

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
  if multi_arch?
    %w[ARM INTEL].each do |arch|
      label = "#{arch.downcase}_url"
      validate_release_url!(ENV.fetch("#{arch}_URL"), label)
      validate_sha256!(ENV.fetch("#{arch}_SHA256"), "#{arch.downcase}_sha256")
    end
  else
    validate_release_url!(ENV.fetch("URL"))
    validate_sha256!(ENV.fetch("SHA256"))
  end
end

def validate_metadata!
  validate_source_repo!
  validate_binary_name!(binary)
  validate_license!(license)
end

def multi_arch?
  arm_url = ENV["ARM_URL"]
  intel_url = ENV["INTEL_URL"]
  arm_url && !arm_url.empty? && intel_url && !intel_url.empty?
end

def multi_arch_formula?(content)
  content.match?(MULTI_ARCH_FORMULA_PATTERN)
end

def upsert_allowed?
  desc = ENV["DESC"]
  homepage = ENV["HOMEPAGE"]
  desc && !desc.empty? && homepage && !homepage.empty?
end

def replace_platform_block!(content, platform, url, sha256)
  block = platform == "arm" ? "on_arm" : "on_intel"
  pattern = /(#{block} do\n\s+url )"[^"]+"\n(\s+sha256 )"[^"]+"/m
  abort("Failed to find #{block} block in #{formula_path}") unless content.match?(pattern)

  content.sub(pattern, "\\1\"#{url}\"\n\\2\"#{sha256}\"")
end

def update_version(content)
  unless content.match?(/^\s*version\s+".*"$/)
    abort("Failed to find version in #{formula_path}")
  end

  content.sub(/^\s*version\s+".*"$/, "  version \"#{ENV.fetch("VERSION")}\"")
end

def update_formula!
  validate_metadata!
  validate_urls_and_checksums!

  path = formula_path
  unless File.file?(path)
    return add_formula! if upsert_allowed?

    abort("Formula not found: #{path}")
  end

  content = File.read(path)
  content = update_version(content)

  if multi_arch?
    abort("Single-arch formula cannot be updated with multi-arch payload") unless multi_arch_formula?(content)

    %w[arm intel].each do |platform|
      key = platform.upcase
      content = replace_platform_block!(
        content,
        platform,
        ENV.fetch("#{key}_URL"),
        ENV.fetch("#{key}_SHA256")
      )
    end
  elsif multi_arch_formula?(content)
    abort("Multi-arch payload is required for #{formula_path}")
  else
    content = replace_platform_block!(
      content,
      "arm",
      ENV.fetch("URL"),
      ENV.fetch("SHA256")
    )
  end

  File.write(path, content)
end

def add_formula!
  validate_metadata!
  validate_urls_and_checksums!
  abort("client_payload.desc is required for add-formula") unless upsert_allowed?

  path = formula_path
  abort("Formula already exists: #{path}") if File.file?(path)

  template = multi_arch? ? multi_arch_template : single_arch_template
  File.write(path, ERB.new(template, trim_mode: "-").result(binding))
end

def single_arch_template
  <<~RUBY
    class <%= class_name %> < Formula
      desc "<%= ruby_string(ENV.fetch("DESC")) %>"
      homepage "<%= ruby_string(ENV.fetch("HOMEPAGE")) %>"
      version "<%= ruby_string(ENV.fetch("VERSION")) %>"
      license "<%= ruby_string(license) %>"

      on_macos do
        on_arm do
          url "<%= ruby_string(ENV.fetch("URL")) %>"
          sha256 "<%= ruby_string(ENV.fetch("SHA256")) %>"
        end
      end

      def install
        bin.install "<%= ruby_string(binary) %>"
      end

      test do
        output = shell_output("\#{bin}/<%= ruby_string(binary) %> --help")
        assert_match "<%= ruby_string(test_match) %>", output
      end
    end
  RUBY
end

def multi_arch_template
  <<~RUBY
    class <%= class_name %> < Formula
      desc "<%= ruby_string(ENV.fetch("DESC")) %>"
      homepage "<%= ruby_string(ENV.fetch("HOMEPAGE")) %>"
      version "<%= ruby_string(ENV.fetch("VERSION")) %>"
      license "<%= ruby_string(license) %>"

      on_macos do
        on_arm do
          url "<%= ruby_string(ENV.fetch("ARM_URL")) %>"
          sha256 "<%= ruby_string(ENV.fetch("ARM_SHA256")) %>"
        end
        on_intel do
          url "<%= ruby_string(ENV.fetch("INTEL_URL")) %>"
          sha256 "<%= ruby_string(ENV.fetch("INTEL_SHA256")) %>"
        end
      end

      def install
        bin.install "<%= ruby_string(binary) %>"
      end

      test do
        output = shell_output("\#{bin}/<%= ruby_string(binary) %> --help")
        assert_match "<%= ruby_string(test_match) %>", output
      end
    end
  RUBY
end

def binary
  ENV.fetch("BINARY", ENV.fetch("FORMULA"))
end

def license
  ENV.fetch("LICENSE", "MIT")
end

def test_match
  ENV.fetch("TEST_MATCH", "USAGE: #{binary}")
end

case ARGV.fetch(0)
when "update"
  update_formula!
when "add"
  add_formula!
else
  abort("Unknown command: #{ARGV.fetch(0)}")
end
