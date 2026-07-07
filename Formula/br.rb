class Br < Formula
  desc "Unofficial Bitrise CLI for build history and logs"
  homepage "https://github.com/novr/bitrise-cli"
  version "0.0.2"
  license "MIT"

  on_macos do
    url "https://github.com/novr/bitrise-cli/releases/download/v0.0.2/br_0.0.2_darwin.tar.gz"
    sha256 "039ec3e45e612460011efe046c3f2aacc2fe0fec465d8fe14f98296e158748a4"
  end

  def install
    bin.install "br"
  end

  test do
    output = shell_output("#{bin}/br --help")
    assert_match "Bitrise CLI", output
  end
end
