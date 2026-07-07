#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "tmpdir"

SCRIPT = File.expand_path("cask_dispatch.rb", __dir__)
SHA256 = "e0d200a665351832dd11a065443d38b504969c77a8660ad4f49fc6405f7d7518"
BASE_ENV = {
  "CASK" => "test-app",
  "VERSION" => "1.0.0",
  "SHA256" => SHA256,
  "DESC" => "Test macOS app",
  "HOMEPAGE" => "https://github.com/novr/Test",
  "SOURCE_REPO" => "novr/Test",
  "APP" => "Test.app",
  "ASSET" => "Test-macOS.zip",
  "MINIMUM_MACOS" => "sonoma"
}.freeze

def assert!(message)
  raise "Assertion failed: #{message}" unless yield
end

def with_workspace
  Dir.mktmpdir("cask-dispatch-test-") do |dir|
    cask_dir = File.join(dir, "Casks")
    FileUtils.mkdir_p(cask_dir)
    Dir.chdir(dir) { yield(dir, cask_dir) }
  end
end

def run_script(command, extra_env = {}, clear_keys: [])
  env = BASE_ENV.merge(extra_env)
  clear_keys.each { |key| env.delete(key) }

  system(env, "ruby", SCRIPT, command)
end

with_workspace do |_dir, cask_dir|
  cask_path = File.join(cask_dir, "test-app.rb")

  assert!("add should succeed") { run_script("add") }
  assert!("cask should be created") { File.file?(cask_path) }

  content = File.read(cask_path)
  assert!("desc should be present") { content.include?('desc "Test macOS app"') }
  assert!("app should be present") { content.include?('app "Test.app"') }
  assert!("sha256 should be present") { content.include?("sha256 \"#{SHA256}\"") }

  assert!("update should succeed") do
    run_script("update", { "VERSION" => "1.0.1", "SHA256" => "a" * 64 })
  end

  updated = File.read(cask_path)
  assert!("version should be updated") { updated.include?('version "1.0.1"') }
  assert!("sha256 should be updated") { updated.include?("sha256 \"#{'a' * 64}\"") }
end

puts "cask_dispatch_test.rb: ok"
