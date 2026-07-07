class KawarimiValidate < Formula
  desc "Fail on structural mock/scenario JSON issues that runtime only warns about."
  homepage "https://github.com/novr/Kawarimi"
  version "3.3.3"
  license "MIT"

  on_macos do
    url "https://github.com/novr/Kawarimi/releases/download/v3.3.3/kawarimi-validate_3.3.3_darwin.tar.gz"
    sha256 "c9163a6f1a43aaf7bb71fc835a5ac7e721ba86c3288d79074cc363548b3f8bee"
  end

  def install
    bin.install "kawarimi-validate"
  end

  test do
    output = shell_output("#{bin}/kawarimi-validate --help")
    assert_match "kawarimi-validate", output
  end
end
