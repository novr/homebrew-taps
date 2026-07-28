    class Utsusemi < Formula
      desc "Ephemeral self-hosted GitHub Actions runners for Apple Silicon Macs"
      homepage "https://github.com/novr/Utsusemi"
  version "0.2.2"
      license "MIT"

      on_macos do
        url "https://github.com/novr/Utsusemi/releases/download/v0.2.2/utsusemi_0.2.2_darwin.tar.gz"
        sha256 "75d3f50497c1cb349a4e8e1a32737ab2f9e7d7759a13e5bbe601caa046775575"
      end

      def install
        bin.install "utsusemi"
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
