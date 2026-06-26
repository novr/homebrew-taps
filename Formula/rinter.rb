class Rinter < Formula
  desc "Run semantic policy checks from Rinfile.swift"
  homepage "https://github.com/novr/Rin"
  version "0.0.8"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/novr/Rin/releases/download/v0.0.8/rinter_0.0.8_darwin_arm64.tar.gz"
      sha256 "083b56106640d17e3c6f6b5d149c951c8ddc2de1bba5bc0f0dddde940eb73a87"
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
