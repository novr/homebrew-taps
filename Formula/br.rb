class Br < Formula
  desc "Unofficial Bitrise CLI for build history and logs"
  homepage "https://github.com/novr/bitrise-cli"
  version "0.3.0"
  license "MIT"

  on_macos do
    url "https://github.com/novr/bitrise-cli/releases/download/v0.3.0/br_0.3.0_darwin.tar.gz"
    sha256 "f79a0fbcb40c1645e9aacf0f0665abaf0b97beaf211e5d29c965f10ed7a1326a"
  end

  def install
    bin.install "br"
  end

  test do
    output = shell_output("#{bin}/br --help")
    assert_match "Bitrise CLI", output
  end
end
