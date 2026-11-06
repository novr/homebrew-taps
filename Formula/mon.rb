    class Mon < Formula
      desc "macOS のアプリアイコンに、ビルド番号やブランチ名の斜めリボンを合成する CLI"
      homepage "https://github.com/novr/Mon"
      version "0.1.0"
      license "MIT"

      on_macos do
        url "https://github.com/novr/Mon/releases/download/v0.1.0/mon_0.1.0_darwin.tar.gz"
        sha256 "e2c18f9815c52f3edb5b5daa8462e2ceb9486824bd3171e2ac344a4dfc146c57"
      end

      def install
        bin.install "mon"
      end

      test do
        output = shell_output("#{bin}/mon --help")
        assert_match "USAGE: mon", output
      end
    end
