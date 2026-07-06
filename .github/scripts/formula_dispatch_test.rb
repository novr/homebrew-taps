#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "tmpdir"

SCRIPT = File.expand_path("formula_dispatch.rb", __dir__)
SHA256 = "e0d200a665351832dd11a065443d38b504969c77a8660ad4f49fc6405f7d7518"
BASE_ENV = {
  "FORMULA" => "test-cli",
  "VERSION" => "1.0.0",
  "URL" => "https://github.com/novr/Test/releases/download/v1.0.0/test-cli_1.0.0_darwin_arm64.tar.gz",
  "SHA256" => SHA256,
  "DESC" => "Test CLI",
  "HOMEPAGE" => "https://github.com/novr/Test",
  "SOURCE_REPO" => "novr/Test",
  "BINARY" => "test-cli"
}.freeze

def assert!(message)
  raise "Assertion failed: #{message}" unless yield
end

def refute!(message)
  raise "Assertion failed: #{message}" if yield
end

def with_workspace
  Dir.mktmpdir("formula-dispatch-test-") do |dir|
    formula_dir = File.join(dir, "Formula")
    FileUtils.mkdir_p(formula_dir)
    Dir.chdir(dir) { yield(dir, formula_dir) }
  end
end

def run_script(command, extra_env = {}, clear_keys: [])
  env = BASE_ENV.merge(extra_env)
  clear_keys.each { |key| env.delete(key) }

  system(env, "ruby", SCRIPT, command)
end

def read_formula(path)
  File.read(path)
end

with_workspace do |dir, formula_dir|
  formula_path = File.join(formula_dir, "test-cli.rb")

  assert!("add should succeed") { run_script("add") }
  assert!("formula should be created") { File.file?(formula_path) }

  content = read_formula(formula_path)
  assert!("desc should be present") { content.include?('desc "Test CLI"') }
  assert!("ruby syntax should be valid") { system("ruby", "-c", formula_path) }

  assert!("add should reject duplicates") { !run_script("add") }

  assert!("update should succeed") do
    run_script(
      "update",
      {
        "VERSION" => "1.0.1",
        "URL" => "https://github.com/novr/Test/releases/download/v1.0.1/test-cli_1.0.1_darwin_arm64.tar.gz"
      }
    )
  end

  updated = read_formula(formula_path)
  assert!("version should be updated") { updated.include?('version "1.0.1"') }
  assert!("url should be updated") { updated.include?("v1.0.1/test-cli_1.0.1_darwin_arm64.tar.gz") }

  assert!("invalid formula name should fail") do
    !run_script("update", { "FORMULA" => "../evil" })
  end

  assert!("invalid binary should fail") do
    !run_script("update", { "BINARY" => 'bad"name' })
  end

  assert!("invalid source_repo should fail") do
    !run_script("update", { "SOURCE_REPO" => "evil/repo" })
  end

  assert!("homepage mismatch should fail") do
    !run_script("update", { "HOMEPAGE" => "https://github.com/novr/Other" })
  end

  assert!("non-release url should fail") do
    !run_script("update", { "URL" => "https://github.com/novr/Other/archive/main.zip" })
  end

  FileUtils.rm_f(formula_path)
  assert!("upsert should create formula") do
    run_script(
      "update",
      {
        "DESC" => "Say \"hello\"\nworld",
        "HOMEPAGE" => "https://github.com/novr/Test"
      }
    )
  end

  upserted = read_formula(formula_path)
  assert!("quoted desc should be escaped") { upserted.include?('desc "Say \\"hello\\"\\nworld"') }
  assert!("upserted formula syntax should be valid") { system("ruby", "-c", formula_path) }
end

puts "formula_dispatch tests passed"
