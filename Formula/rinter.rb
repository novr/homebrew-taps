class Rinter < Formula
  desc "Run semantic policy checks from Rinfile.swift"
  homepage "https://github.com/novr/Rin"
  version "0.0.4"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/novr/Rin/releases/download/v0.0.4/rinter_0.0.4_darwin_arm64.tar.gz"
      sha256 "a0cf94bf10f4f9ff7ea3a7b207e96c9bf492993ae737018afd0aa1bfc27409f8"
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
