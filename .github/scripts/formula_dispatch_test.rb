#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "tmpdir"

SCRIPT = File.expand_path("formula_dispatch.rb", __dir__)
SHA256 = "e0d200a665351832dd11a065443d38b504969c77a8660ad4f49fc6405f7d7518"
BASE_ENV = {
  "FORMULA" => "test-cli",
  "VERSION" => "1.0.0",
  "URL" => "https://github.com/novr/Test/releases/download/v1.0.0/test-cli_1.0.0_darwin.tar.gz",
  "SHA256" => SHA256,
  "DESC" => "Test CLI",
  "HOMEPAGE" => "https://github.com/novr/Test",
  "SOURCE_REPO" => "novr/Test",
  "BINARY" => "test-cli"
}.freeze

LEGACY_FORMULA = <<~RUBY
  class TestCli < Formula
    desc "Legacy"
    homepage "https://github.com/novr/Test"
    version "0.9.0"
    license "MIT"

    on_macos do
      on_arm do
        url "https://github.com/novr/Test/releases/download/v0.9.0/test-cli_0.9.0_darwin_arm64.tar.gz"
        sha256 "#{SHA256}"
      end
    end

    def install
      bin.install "test-cli"
    end

    test do
      output = shell_output("\#{bin}/test-cli --help")
      assert_match "USAGE: test-cli", output
    end
  end
RUBY

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
  assert!("formula should use universal on_macos block") { content.match?(/on_macos do\n\s+url /) }
  refute!("formula should not use on_arm block") { content.include?("on_arm do") }
  assert!("ruby syntax should be valid") { system("ruby", "-c", formula_path) }

  assert!("add should update an existing formula") do
    run_script(
      "add",
      {
        "VERSION" => "1.0.2",
        "URL" => "https://github.com/novr/Test/releases/download/v1.0.2/test-cli_1.0.2_darwin.tar.gz"
      }
    )
  end

  added_again = read_formula(formula_path)
  assert!("add should bump version on existing formula") { added_again.include?('version "1.0.2"') }

  assert!("update should succeed") do
    run_script(
      "update",
      {
        "VERSION" => "1.0.1",
        "URL" => "https://github.com/novr/Test/releases/download/v1.0.1/test-cli_1.0.1_darwin.tar.gz"
      }
    )
  end

  updated = read_formula(formula_path)
  assert!("version should be updated") { updated.include?('version "1.0.1"') }
  assert!("url should be updated") { updated.include?("v1.0.1/test-cli_1.0.1_darwin.tar.gz") }

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

  legacy_path = File.join(formula_dir, "legacy-cli.rb")
  File.write(legacy_path, LEGACY_FORMULA.gsub("TestCli", "LegacyCli").gsub("test-cli", "legacy-cli"))

  assert!("legacy formula should migrate on update") do
    run_script(
      "update",
      {
        "FORMULA" => "legacy-cli",
        "VERSION" => "1.0.0",
        "URL" => "https://github.com/novr/Test/releases/download/v1.0.0/legacy-cli_1.0.0_darwin.tar.gz"
      }
    )
  end

  legacy_updated = read_formula(legacy_path)
  assert!("legacy formula should drop on_arm block") { !legacy_updated.include?("on_arm do") }
  assert!("legacy formula should use universal url") do
    legacy_updated.include?("legacy-cli_1.0.0_darwin.tar.gz")
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

  FileUtils.rm_f(formula_path)
  assert!("add with brew service should succeed") do
    run_script(
      "add",
      {
        "FORMULA" => "svc-cli",
        "BINARY" => "svc-cli",
        "SERVICE_RUN_ARGS" => "run,--config",
        "SERVICE_CONFIG" => "svc-cli/config.yaml",
        "SERVICE_CONFIG_SOURCE" => "config.yaml.example"
      }
    )
  end

  service_path = File.join(formula_dir, "svc-cli.rb")
  service_content = read_formula(service_path)
  assert!("service block should be present") { service_content.include?("service do") }
  assert!("service should use configured run args") do
    service_content.include?('run [opt_bin/"svc-cli", "run", "--config", etc/"svc-cli/config.yaml"]')
  end
  assert!("install should copy config template") do
    service_content.include?('etc.install "config.yaml.example" => "svc-cli/config.yaml"')
  end
  assert!("service formula syntax should be valid") { system("ruby", "-c", service_path) }

  assert!("update should preserve service block") do
    run_script(
      "update",
      {
        "FORMULA" => "svc-cli",
        "BINARY" => "svc-cli",
        "VERSION" => "1.0.1",
        "URL" => "https://github.com/novr/Test/releases/download/v1.0.1/svc-cli_1.0.1_darwin.tar.gz"
      }
    )
  end

  updated_service = read_formula(service_path)
  assert!("service block should remain after update") { updated_service.include?("service do") }

  FileUtils.rm_f(service_path)
  assert!("add with service_run_args only should succeed") do
    run_script(
      "add",
      {
        "FORMULA" => "daemon-cli",
        "BINARY" => "daemon-cli",
        "SERVICE_RUN_ARGS" => "start"
      }
    )
  end

  daemon_path = File.join(formula_dir, "daemon-cli.rb")
  daemon_content = read_formula(daemon_path)
  assert!("daemon service should not reference etc") { !daemon_content.include?('etc/"') }
  assert!("daemon service should use start arg") do
    daemon_content.include?('run [opt_bin/"daemon-cli", "start"]')
  end

  assert!("service_config without service_run_args should install etc only") do
    run_script(
      "add",
      {
        "FORMULA" => "cfg-cli",
        "BINARY" => "cfg-cli",
        "SERVICE_CONFIG" => "cfg-cli/config.yaml",
        "SERVICE_CONFIG_SOURCE" => "config.yaml.example"
      }
    )
  end

  cfg_path = File.join(formula_dir, "cfg-cli.rb")
  cfg_content = read_formula(cfg_path)
  assert!("config-only formula should not have service block") { !cfg_content.include?("service do") }
  assert!("config-only formula should install config template") do
    cfg_content.include?('etc.install "config.yaml.example" => "cfg-cli/config.yaml"')
  end

  assert!("invalid service_config should fail") do
    !run_script(
      "add",
      {
        "FORMULA" => "bad-svc",
        "SERVICE_RUN_ARGS" => "run,--config",
        "SERVICE_CONFIG" => "../etc/passwd"
      }
    )
  end

  assert!("invalid service_run_args should fail") do
    !run_script(
      "add",
      {
        "FORMULA" => "bad-svc",
        "BINARY" => "bad-svc",
        "SERVICE_RUN_ARGS" => "run,,start"
      }
    )
  end

  assert!("update should ignore invalid brew service fields") do
    run_script(
      "update",
      {
        "FORMULA" => "daemon-cli",
        "BINARY" => "daemon-cli",
        "VERSION" => "1.0.2",
        "URL" => "https://github.com/novr/Test/releases/download/v1.0.2/daemon-cli_1.0.2_darwin.tar.gz",
        "SERVICE_RUN_ARGS" => "bad arg"
      }
    )
  end

  FileUtils.rm_f(formula_path)
  assert!("add with shell completions should succeed") do
    run_script(
      "add",
      {
        "FORMULA" => "cmp-cli",
        "BINARY" => "cmp-cli",
        "COMPLETION_SHELLS" => "bash,zsh,fish",
        "COMPLETION_FORMAT" => "cobra"
      }
    )
  end

  cmp_path = File.join(formula_dir, "cmp-cli.rb")
  cmp_content = read_formula(cmp_path)
  assert!("completion install line should be present") do
    cmp_content.include?('generate_completions_from_executable(bin/"cmp-cli", shells: [:bash, :zsh, :fish], shell_parameter_format: :cobra)')
  end
  assert!("completion formula syntax should be valid") { system("ruby", "-c", cmp_path) }

  assert!("add with custom completion args should succeed") do
    run_script(
      "add",
      {
        "FORMULA" => "statoo-cli",
        "BINARY" => "statoo-cli",
        "COMPLETION_SHELLS" => "bash",
        "COMPLETION_ARGS" => "bash-completion,completions"
      }
    )
  end

  statoo_path = File.join(formula_dir, "statoo-cli.rb")
  statoo_content = read_formula(statoo_path)
  assert!("custom completion args should be emitted") do
    statoo_content.include?('generate_completions_from_executable(bin/"statoo-cli", "bash-completion", "completions", shells: [:bash])')
  end

  assert!("invalid completion_shells should fail") do
    !run_script(
      "add",
      {
        "FORMULA" => "bad-cmp",
        "COMPLETION_SHELLS" => "bash,invalid"
      }
    )
  end

  assert!("completion_format without completion_shells should fail") do
    !run_script(
      "add",
      {
        "FORMULA" => "bad-cmp",
        "COMPLETION_FORMAT" => "cobra"
      }
    )
  end

  assert!("completion shells with spaces should succeed") do
    run_script(
      "add",
      {
        "FORMULA" => "spaced-cmp",
        "BINARY" => "spaced-cmp",
        "COMPLETION_SHELLS" => "bash, zsh"
      }
    )
  end

  spaced_path = File.join(formula_dir, "spaced-cmp.rb")
  spaced_content = read_formula(spaced_path)
  assert!("spaced completion shells should be normalized") do
    spaced_content.include?("shells: [:bash, :zsh]")
  end

  assert!("update should ignore invalid completion fields") do
    run_script(
      "update",
      {
        "FORMULA" => "cmp-cli",
        "BINARY" => "cmp-cli",
        "VERSION" => "1.0.1",
        "URL" => "https://github.com/novr/Test/releases/download/v1.0.1/cmp-cli_1.0.1_darwin.tar.gz",
        "COMPLETION_SHELLS" => "bad"
      }
    )
  end

  updated_cmp = read_formula(cmp_path)
  assert!("completion install line should remain after update") do
    updated_cmp.include?("generate_completions_from_executable")
  end

  FileUtils.rm_f(formula_path)
  assert!("add with multiple binaries and aliases should succeed") do
    run_script(
      "add",
      {
        "FORMULA" => "multi-cli",
        "BINARY" => "multi-cli",
        "BINARIES" => "multi-cli,short-cli,git-multi",
        "ALIASES" => "short-cli,git-multi",
        "COMPLETION_SHELLS" => "bash",
        "COMPLETION_FORMAT" => "cobra"
      }
    )
  end

  multi_path = File.join(formula_dir, "multi-cli.rb")
  multi_content = read_formula(multi_path)
  assert!("multiple binaries should be installed") do
    multi_content.include?('bin.install "multi-cli", "short-cli", "git-multi"')
  end
  assert!("alias files should be created") do
    File.file?(File.join(dir, "Aliases", "short-cli")) &&
      File.read(File.join(dir, "Aliases", "short-cli")).strip == "multi-cli" &&
      File.read(File.join(dir, "Aliases", "git-multi")).strip == "multi-cli"
  end
  assert!("multi formula syntax should be valid") { system("ruby", "-c", multi_path) }

  assert!("invalid binaries should fail") do
    !run_script(
      "add",
      {
        "FORMULA" => "bad-bin",
        "BINARIES" => "good,bad name"
      }
    )
  end

  assert!("alias matching formula should fail") do
    !run_script(
      "add",
      {
        "FORMULA" => "self-alias",
        "BINARIES" => "self-alias,short-cli",
        "ALIASES" => "self-alias"
      }
    )
  end

  assert!("binaries without primary binary should fail") do
    !run_script(
      "add",
      {
        "FORMULA" => "missing-primary",
        "BINARY" => "missing-primary",
        "BINARIES" => "short-cli"
      }
    )
  end

  assert!("alias not in binaries should fail") do
    !run_script(
      "add",
      {
        "FORMULA" => "alias-gap",
        "BINARIES" => "alias-gap,short-cli",
        "ALIASES" => "missing-cli"
      }
    )
  end

  assert!("add on existing formula should still write aliases") do
    run_script(
      "add",
      {
        "FORMULA" => "multi-cli",
        "BINARY" => "multi-cli",
        "VERSION" => "1.0.1",
        "URL" => "https://github.com/novr/Test/releases/download/v1.0.1/multi-cli_1.0.1_darwin.tar.gz",
        "BINARIES" => "multi-cli,short-cli,git-multi",
        "ALIASES" => "short-cli,git-multi"
      }
    )
  end

  assert!("alias files should remain after add on existing formula") do
    File.file?(File.join(dir, "Aliases", "short-cli")) &&
      File.read(File.join(dir, "Aliases", "short-cli")).strip == "multi-cli"
  end

  File.write(File.join(formula_dir, "conflict-cli.rb"), LEGACY_FORMULA.gsub("TestCli", "ConflictCli").gsub("test-cli", "conflict-cli"))
  assert!("alias conflicting with existing formula should fail") do
    !run_script(
      "add",
      {
        "FORMULA" => "multi-cli",
        "BINARY" => "multi-cli",
        "BINARIES" => "multi-cli,conflict-cli",
        "ALIASES" => "conflict-cli"
      }
    )
  end
end

puts "formula_dispatch tests passed"
