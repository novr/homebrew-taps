#!/usr/bin/env ruby
# frozen_string_literal: true

require "erb"
require "fileutils"

CASK_NAME_PATTERN = /\A[a-z0-9-]+\z/
VERSION_PATTERN = /\A[A-Za-z0-9._-]+\z/
APP_NAME_PATTERN = /\A[A-Za-z0-9._-]+\.app\z/
ASSET_NAME_PATTERN = /\A[A-Za-z0-9._-]+\z/
MACOS_SYMBOL_PATTERN = /\A[a-z0-9_]+\z/
SHA256_PATTERN = /\A[a-f0-9]{64}\z/i
SOURCE_REPO_PATTERN = /\Anovr\/[A-Za-z0-9._-]+\z/

def cask_path
  name = ENV.fetch("CASK")
  abort("Invalid cask name: #{name}") unless name.match?(CASK_NAME_PATTERN)

  path = File.expand_path("Casks/#{name}.rb", Dir.pwd)
  cask_dir = File.expand_path("Casks", Dir.pwd)
  abort("Invalid cask path: #{path}") unless path.start_with?("#{cask_dir}/")

  path
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

def validate_metadata!
  validate_source_repo!

  version = ENV.fetch("VERSION")
  abort("Invalid version: #{version}") unless version.match?(VERSION_PATTERN)

  validate_sha256!(ENV.fetch("SHA256"))

  app = ENV.fetch("APP")
  abort("Invalid app name: #{app}") unless app.match?(APP_NAME_PATTERN)

  asset = ENV.fetch("ASSET")
  abort("Invalid asset name: #{asset}") unless asset.match?(ASSET_NAME_PATTERN)

  minimum_macos = ENV.fetch("MINIMUM_MACOS")
  abort("Invalid minimum_macos: #{minimum_macos}") unless minimum_macos.match?(MACOS_SYMBOL_PATTERN)
end

def upsert_allowed?
  desc = ENV["DESC"]
  homepage = ENV["HOMEPAGE"]
  desc && !desc.empty? && homepage && !homepage.empty?
end

def update_version(content)
  unless content.match?(/^\s*version\s+".*"$/)
    abort("Failed to find version in #{cask_path}")
  end

  content.sub(/^\s*version\s+".*"$/, "  version \"#{ruby_string(ENV.fetch("VERSION"))}\"")
end

def update_sha256(content)
  unless content.match?(/^\s*sha256\s+".*"$/)
    abort("Failed to find sha256 in #{cask_path}")
  end

  content.sub(/^\s*sha256\s+".*"$/, "  sha256 \"#{ENV.fetch("SHA256")}\"")
end

def update_cask!
  validate_metadata!

  path = cask_path
  unless File.file?(path)
    return add_cask! if upsert_allowed?

    abort("Cask not found: #{path}")
  end

  content = File.read(path)
  content = update_version(content)
  content = update_sha256(content)

  File.write(path, content)
end

def add_cask!
  validate_metadata!
  abort("client_payload.desc is required for add-cask") unless upsert_allowed?

  path = cask_path
  return update_cask! if File.file?(path)

  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, ERB.new(cask_template, trim_mode: "-").result(binding))
end

def cask_template
  <<~RUBY
    cask "<%= ruby_string(ENV.fetch("CASK")) %>" do
      version "<%= ruby_string(ENV.fetch("VERSION")) %>"
      sha256 "<%= ruby_string(ENV.fetch("SHA256")) %>"

      url "https://github.com/<%= ruby_string(source_repo) %>/releases/download/v\#{version}/<%= ruby_string(ENV.fetch("ASSET")) %>",
          verified: "github.com/<%= ruby_string(source_repo) %>/"
      name "<%= ruby_string(display_name) %>"
      desc "<%= ruby_string(ENV.fetch("DESC")) %>"
      homepage "<%= ruby_string(ENV.fetch("HOMEPAGE")) %>"

      depends_on macos: :<%= ruby_string(ENV.fetch("MINIMUM_MACOS")) %>

      app "<%= ruby_string(ENV.fetch("APP")) %>"
    end
  RUBY
end

def display_name
  value = ENV["NAME"]
  value = ENV.fetch("CASK") if value.nil? || value.empty?
  value.split("-").map(&:capitalize).join(" ")
end

case ARGV.fetch(0)
when "update"
  update_cask!
when "add"
  add_cask!
else
  abort("Unknown command: #{ARGV.fetch(0)}")
end
