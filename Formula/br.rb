class Br < Formula
  desc "Unofficial Bitrise CLI for build history and logs"
  homepage "https://github.com/novr/bitrise-cli"
  version "0.1.0"
  license "MIT"

  on_macos do
    url "https://github.com/novr/bitrise-cli/releases/download/v0.1.0/br_0.1.0_darwin.tar.gz"
    sha256 "319d72a6fef243cc298d09f9d8770d775ac5e25d1db93a5fcb9f7a45f0019fdb"
  end

  def install
    bin.install "br"
  end

  test do
    output = shell_output("#{bin}/br --help")
    assert_match "Bitrise CLI", output
  end
end
