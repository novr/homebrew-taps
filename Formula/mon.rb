    class Mon < Formula
      desc "macOS のアプリアイコンに、ビルド番号やブランチ名の斜めリボンを合成する CLI"
      homepage "https://github.com/novr/Mon"
  version "0.2.0"
      license "MIT"

      on_macos do
        url "https://github.com/novr/Mon/releases/download/v0.2.0/mon_0.2.0_darwin.tar.gz"
        sha256 "b71a7a5bc06d2aadff493932be417b4e27304160284f8819d0f56133375e4843"
      end

      def install
        bin.install "mon"
      end

      test do
        output = shell_output("#{bin}/mon --help")
        assert_match "USAGE: mon", output
      end
    end
