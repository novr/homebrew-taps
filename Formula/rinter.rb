class Rinter < Formula
  desc "Run semantic policy checks from Rinfile.swift"
  homepage "https://github.com/novr/Rin"
  version "0.0.9"
  license "MIT"

  on_macos do
    url "https://github.com/novr/Rin/releases/download/v0.0.9/rinter_0.0.9_darwin_arm64.tar.gz"
    sha256 "e0d200a665351832dd11a065443d38b504969c77a8660ad4f49fc6405f7d7518"
  end

  def install
    bin.install "rinter"
  end

  test do
    output = shell_output("#{bin}/rinter --help")
    assert_match "USAGE: rinter", output
  end
end
