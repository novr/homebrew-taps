    class Utsusemi < Formula
      desc "Ephemeral self-hosted GitHub Actions runners for Apple Silicon Macs"
      homepage "https://github.com/novr/Utsusemi"
  version "0.27.0"
      license "MIT"

      on_macos do
        url "https://github.com/novr/Utsusemi/releases/download/v0.27.0/utsusemi_0.27.0_darwin.tar.gz"
        sha256 "bd8fe3d9f681e9ee0cb899e27eae99c1b1a7366d255b9d49a46e0a0269b440ff"
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
