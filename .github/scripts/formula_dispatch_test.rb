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

def alias_symlink?(dir, name, formula)
  path = File.join(dir, "Aliases", name)
  File.symlink?(path) &&
    File.readlink(path) == "../Formula/#{formula}.rb" &&
    File.file?(path)
end

with_workspace do |dir, formula_dir|
  formula_path = File.join(formula_dir, "test-cli.rb")

  assert!("add should succeed") { run_script("add") }
  assert!("formula should be created") { File.file?(formula_path) }

  content = read_formula(formula_path)
  assert!("desc should be present") { content.include?('desc "Test CLI"') }
  assert!("formula should declare a top-level url") { content.match?(/^\s+url "/) }
  assert!("formula should depend on macos") { content.include?("depends_on :macos") }
  refute!("formula should not hide the url in on_macos") { content.include?("on_macos do") }
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
  assert!("update should keep a single macos requirement") do
    updated.scan("depends_on :macos").length == 1
  end

  File.write(formula_path, updated.sub(/^( *version "1.0.1"\n)/, "\\1  revision 1\n"))
  assert!("same version update should keep revision") do
    run_script(
      "update",
      {
        "VERSION" => "1.0.1",
        "URL" => "https://github.com/novr/Test/releases/download/v1.0.1/test-cli_1.0.1_darwin.tar.gz"
      }
    )
  end
  assert!("revision should remain when version is unchanged") do
    read_formula(formula_path).include?("revision 1")
  end

  assert!("version bump should drop revision") do
    run_script(
      "update",
      {
        "VERSION" => "1.0.3",
        "URL" => "https://github.com/novr/Test/releases/download/v1.0.3/test-cli_1.0.3_darwin.tar.gz"
      }
    )
  end
  bumped = read_formula(formula_path)
  assert!("revision should be removed after a version bump") { !bumped.include?("revision") }
  assert!("bumped version should be written") { bumped.include?('version "1.0.3"') }

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

  os_path = File.join(formula_dir, "os-cli.rb")
  os_original = <<~RUBY
    class OsCli < Formula
      desc "OS"
      homepage "https://github.com/novr/Test"
      version "0.9.0"
      license "MIT"

      on_macos do
        url "https://github.com/novr/Test/releases/download/v0.9.0/os-cli_0.9.0_darwin.tar.gz"
        sha256 "#{SHA256}"
      end
    end
  RUBY
  File.write(os_path, os_original)
  assert!("os url should fail") do
    !run_script(
      "update",
      {
        "FORMULA" => "os-cli",
        "VERSION" => "1.0.0",
        "URL" => "https://github.com/novr/Test/releases/download/v1.0.0/os-cli_1.0.0_darwin.tar.gz"
      }
    )
  end
  assert!("os url should leave the formula unchanged") do
    read_formula(os_path) == os_original
  end

  quoted_path = File.join(formula_dir, "quoted-url-cli.rb")
  head_url = "https://github.com/novr/Test.git"
  File.write(quoted_path, <<~RUBY)
    class QuotedUrlCli < Formula
      desc "Quoted"
      homepage "https://github.com/novr/Test"
      version "0.9.0"
      license "MIT"

      url "https://github.com/novr/Test/releases/download/v0.9.0/quoted-url-cli_0.9.0_darwin.tar.gz"
      sha256 "#{SHA256}"
      depends_on :macos

      def install
        on_macos do
          bin.install "quoted-url-cli"
        end
      end

      head do
        url "#{head_url}"
      end
    end
  RUBY
  quoted_url = "https://github.com/novr/Test/releases/download/v1.0.0/quoted-url-cli_1.0.0_\"darwin.tar.gz"
  assert!("quoted url should update a top-level formula") do
    run_script(
      "update",
      {
        "FORMULA" => "quoted-url-cli",
        "VERSION" => "1.0.0",
        "URL" => quoted_url
      }
    )
  end
  quoted_updated = read_formula(quoted_path)
  assert!("quoted url should be escaped") { quoted_updated.include?('url "https://github.com/novr/Test/releases/download/v1.0.0/quoted-url-cli_1.0.0_\\"darwin.tar.gz"') }
  assert!("install on_macos block should stay") { quoted_updated.include?("on_macos do") }
  assert!("head url after install on_macos should stay") { quoted_updated.include?("url \"#{head_url}\"") }
  assert!("quoted formula syntax should be valid") { system("ruby", "-c", quoted_path) }

  system_path = File.join(formula_dir, "system-cli.rb")
  system_original = <<~RUBY
    class SystemCli < Formula
      desc "System"
      homepage "https://github.com/novr/Test"
      version "0.9.0"
      license "MIT"

      on_system :linux do
        url "https://github.com/novr/Test/releases/download/v0.9.0/system-cli_0.9.0_linux.tar.gz"
        sha256 "#{SHA256}"
      end
    end
  RUBY
  File.write(system_path, system_original)
  assert!("on_system url should fail") do
    !run_script(
      "update",
      {
        "FORMULA" => "system-cli",
        "VERSION" => "1.0.0",
        "URL" => "https://github.com/novr/Test/releases/download/v1.0.0/system-cli_1.0.0_darwin.tar.gz"
      }
    )
  end
  assert!("on_system url should leave the formula unchanged") do
    read_formula(system_path) == system_original
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
    alias_symlink?(dir, "short-cli", "multi-cli") &&
      alias_symlink?(dir, "git-multi", "multi-cli")
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
    alias_symlink?(dir, "short-cli", "multi-cli") &&
      alias_symlink?(dir, "git-multi", "multi-cli")
  end
  assert!("formula should stay a regular file after alias add") do
    File.file?(multi_path) && !File.symlink?(multi_path) &&
      read_formula(multi_path).include?("class MultiCli < Formula")
  end

  short_cli = File.join(dir, "Aliases", "short-cli")
  File.unlink(short_cli)
  File.write(short_cli, "multi-cli\n")
  assert!("add should replace a plain-text alias with a symlink") do
    run_script(
      "add",
      {
        "FORMULA" => "multi-cli",
        "BINARY" => "multi-cli",
        "BINARIES" => "multi-cli,short-cli,git-multi",
        "ALIASES" => "short-cli,git-multi"
      }
    )
  end
  assert!("plain-text alias should become a symlink") do
    alias_symlink?(dir, "short-cli", "multi-cli")
  end
  assert!("formula should not be overwritten through an alias") do
    read_formula(multi_path).include?("class MultiCli < Formula")
  end

  git_multi = File.join(dir, "Aliases", "git-multi")
  File.unlink(git_multi)
  File.write(git_multi, "other-cli\n")
  assert!("alias pointing at another formula should fail") do
    !run_script(
      "add",
      {
        "FORMULA" => "multi-cli",
        "BINARY" => "multi-cli",
        "BINARIES" => "multi-cli,short-cli,git-multi",
        "ALIASES" => "git-multi"
      }
    )
  end
  assert!("mismatched alias should stay untouched") do
    !File.symlink?(git_multi) && File.read(git_multi).strip == "other-cli"
  end

  File.write(File.join(formula_dir, "conflict-cli.rb"), <<~RUBY)
    class ConflictCli < Formula
      desc "Conflict"
      homepage "https://github.com/novr/Test"
      version "1.0.0"
      license "MIT"
      url "https://github.com/novr/Test/releases/download/v1.0.0/conflict-cli_1.0.0_darwin.tar.gz"
      sha256 "#{SHA256}"
      depends_on :macos
    end
  RUBY
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
