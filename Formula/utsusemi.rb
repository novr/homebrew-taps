    class Utsusemi < Formula
      desc "Ephemeral self-hosted GitHub Actions runners for Apple Silicon Macs"
      homepage "https://github.com/novr/Utsusemi"
  version "0.16.0"
      license "MIT"

      on_macos do
        url "https://github.com/novr/Utsusemi/releases/download/v0.16.0/utsusemi_0.16.0_darwin.tar.gz"
        sha256 "6442356a44ecbd02b246ba3f2c0bac567d7b9833819a5e65ea658fb844b9c942"
      end

      def install
        bin.install "utsusemi"
        generate_completions_from_executable(bin/"utsusemi", shell_parameter_format: :cobra)
      end

      service do
        run [opt_bin/"utsusemi", "run", "--log"]
        keep_alive true
        log_path var/"log/utsusemi.log"
        error_log_path var/"log/utsusemi.error.log"
        environment_variables PATH: std_service_path_env
      end
      test do
        output = shell_output("#{bin}/utsusemi --help")
        assert_match "Ephemeral self-hosted", output
      end
    end
