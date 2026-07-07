class Br < Formula
  desc "Unofficial Bitrise CLI for build history and logs"
  homepage "https://github.com/novr/bitrise-cli"
  version "0.0.4"
  license "MIT"

  on_macos do
    url "https://github.com/novr/bitrise-cli/releases/download/v0.0.4/br_0.0.4_darwin.tar.gz"
    sha256 "25b21bad4166d4c136999ee4519fa78180296961db9aa2e2eb86f55931d0550c"
  end

  def install
    bin.install "br"
  end

  test do
    output = shell_output("#{bin}/br --help")
    assert_match "Bitrise CLI", output
  end
end
