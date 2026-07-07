class Rinter < Formula
  desc "Run semantic policy checks from Rinfile.swift"
  homepage "https://github.com/novr/Rin"
  version "0.0.10"
  license "MIT"

  on_macos do
    url "https://github.com/novr/Rin/releases/download/v0.0.10/rinter_0.0.10_darwin.tar.gz"
    sha256 "2a5c290a230fd7b3cb202e5ba035127f877e77a4f905704115df09b786004bcf"
  end

  def install
    bin.install "rinter"
  end

  test do
    output = shell_output("#{bin}/rinter --help")
    assert_match "USAGE: rinter", output
  end
end
