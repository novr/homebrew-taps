class Br < Formula
  desc "Unofficial Bitrise CLI for build history and logs"
  homepage "https://github.com/novr/bitrise-cli"
  version "0.0.1"
  license "MIT"

  on_macos do
    url "https://github.com/novr/bitrise-cli/releases/download/v0.0.1/br_0.0.1_darwin.tar.gz"
    sha256 "29a23f5f6fadf3374d885567cf88ed4d8056aaadb75e3ae7a607a6954b2a552d"
  end

  def install
    bin.install "br"
  end

  test do
    output = shell_output("#{bin}/br --help")
    assert_match "Bitrise CLI", output
  end
end
