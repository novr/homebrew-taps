    class Utsusemi < Formula
      desc "Ephemeral self-hosted GitHub Actions runners for Apple Silicon Macs"
      homepage "https://github.com/novr/Utsusemi"
  version "0.2.1"
      license "MIT"

      on_macos do
        url "https://github.com/novr/Utsusemi/releases/download/v0.2.1/utsusemi_0.2.1_darwin.tar.gz"
        sha256 "b5bd58ded9468d84e08ba9dfa143d77b3f353ed9d98aab0cce53ef979acf1dcf"
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
