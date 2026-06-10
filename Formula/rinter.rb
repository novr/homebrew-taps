class Rinter < Formula
  desc "Run semantic policy checks from Rinfile.swift"
  homepage "https://github.com/novr/Rin"
  version "0.0.2"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/novr/Rin/releases/download/v0.0.2/rinter_0.0.2_darwin_arm64.tar.gz"
      sha256 "43aa921e64edef2bbf72bac1681c4985d272df2b419aaff2179f737c860a01e1"
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
