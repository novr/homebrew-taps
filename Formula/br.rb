class Br < Formula
  desc "Unofficial Bitrise CLI for build history and logs"
  homepage "https://github.com/novr/bitrise-cli"
  version "0.0.3"
  license "MIT"

  on_macos do
    url "https://github.com/novr/bitrise-cli/releases/download/v0.0.3/br_0.0.3_darwin.tar.gz"
    sha256 "9bbe616596a3d0a95b0d405cee0ac14e7b5bb5c9e32b4263f4aa7447aa80f9e3"
  end

  def install
    bin.install "br"
  end

  test do
    output = shell_output("#{bin}/br --help")
    assert_match "Bitrise CLI", output
  end
end
