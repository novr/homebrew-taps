    class Utsusemi < Formula
      desc "Ephemeral self-hosted GitHub Actions runners for Apple Silicon Macs"
      homepage "https://github.com/novr/Utsusemi"
  version "0.25.0"
      license "MIT"

      on_macos do
        url "https://github.com/novr/Utsusemi/releases/download/v0.25.0/utsusemi_0.25.0_darwin.tar.gz"
        sha256 "688f9dec49119e8cc3f0654c581bb7416e54fbf7704975f57620e8832f2ddbfd"
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
