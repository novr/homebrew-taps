class Br < Formula
  desc "Unofficial Bitrise CLI for build history and logs"
  homepage "https://github.com/novr/bitrise-cli"
  version "0.0.2"
  license "MIT"

  on_macos do
    url "https://github.com/novr/bitrise-cli/releases/download/v0.0.2/br_0.0.2_darwin.tar.gz"
    sha256 "3178609d198f1624ae8f1437ec22c642bd6e6586c4205b27979ac2825a1fdec3"
  end

  def install
    bin.install "br"
  end

  test do
    output = shell_output("#{bin}/br --help")
    assert_match "Bitrise CLI", output
  end
end
