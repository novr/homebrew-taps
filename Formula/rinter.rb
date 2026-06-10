class Rinter < Formula
  desc "Run semantic policy checks from Rinfile.swift"
  homepage "https://github.com/novr/Rin"
  version "0.0.3"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/novr/Rin/releases/download/v0.0.3/rinter_0.0.3_darwin_arm64.tar.gz"
      sha256 "7618b7b2dadd969836c0e8b9cf17925bad1a1102dd6752bfd2baa1fe4dfad062"
    end
  end

  def install
    bin.install "rinter"
  end

  test do
    output = shell_output("#{bin}/rinter --help")
    assert_match "USAGE: rinter", output
  end
end
