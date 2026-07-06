class Rinter < Formula
  desc "Run semantic policy checks from Rinfile.swift"
  homepage "https://github.com/novr/Rin"
  version "0.0.10"
  license "MIT"

  on_macos do
    url "https://github.com/novr/Rin/releases/download/v0.0.10/rinter_0.0.10_darwin.tar.gz"
    sha256 "ecb926d86f58147aa45881e98a78430f8f05d374c0d9a53e42455f2ae94b6358"
  end

  def install
    bin.install "rinter"
  end

  test do
    output = shell_output("#{bin}/rinter --help")
    assert_match "USAGE: rinter", output
  end
end
