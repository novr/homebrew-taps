    class Utsusemi < Formula
      desc "Ephemeral self-hosted GitHub Actions runners for Apple Silicon Macs"
      homepage "https://github.com/novr/Utsusemi"
  version "0.11.0"
      license "MIT"

      on_macos do
        url "https://github.com/novr/Utsusemi/releases/download/v0.11.0/utsusemi_0.11.0_darwin.tar.gz"
        sha256 "f9f74097b385e672f9f3c03e9bc01f86a34fa87aaae4fcf1f26c0656c5f2d865"
      end

      def install
        bin.install "utsusemi"
        generate_completions_from_executable(bin/"utsusemi", shell_parameter_format: :cobra)
      end

      service do
        run [opt_bin/"utsusemi", "run"]
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
