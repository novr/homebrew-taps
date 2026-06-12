class Rinter < Formula
  desc "Run semantic policy checks from Rinfile.swift"
  homepage "https://github.com/novr/Rin"
  version "0.0.7"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/novr/Rin/releases/download/v0.0.7/rinter_0.0.7_darwin_arm64.tar.gz"
      sha256 "dbdf44755dc34bf57e03de529ae148a741f3302ff922ee81307bcb7169dabbc1"
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
