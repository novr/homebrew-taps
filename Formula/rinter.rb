class Rinter < Formula
  desc "Run semantic policy checks from Rinfile.swift"
  homepage "https://github.com/novr/Rin"
  version "0.0.1"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/novr/Rin/releases/download/v#{version}/rinter_#{version}_darwin_arm64.tar.gz"
      sha256 "cfb8c83f84e5447dca3b76daac096c185f6ae54fb5c823569acfcc2fd6177b52"
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
