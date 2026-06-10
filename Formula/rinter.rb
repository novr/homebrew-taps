class Rinter < Formula
  desc "Run semantic policy checks from Rinfile.swift"
  homepage "https://github.com/novr/Rin"
  version "0.0.5"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/novr/Rin/releases/download/v0.0.5/rinter_0.0.5_darwin_arm64.tar.gz"
      sha256 "d0e972f7496e83990691854b2c032b7b66bb42149142c01d273f0e3dbdbfd939"
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
