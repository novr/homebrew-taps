    class Mon < Formula
      desc "macOS のアプリアイコンに、ビルド番号やブランチ名の斜めリボンを合成する CLI"
      homepage "https://github.com/novr/Mon"
  version "0.3.0"
      license "MIT"

      on_macos do
        url "https://github.com/novr/Mon/releases/download/v0.3.0/mon_0.3.0_darwin.tar.gz"
        sha256 "3bce4bc0c0ac7f37fe3793ff76eb9ea7f3b351decbc98547083926dd87dbabe0"
      end

      def install
        bin.install "mon"
      end

      test do
        output = shell_output("#{bin}/mon --help")
        assert_match "USAGE: mon", output
      end
    end
