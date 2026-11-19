class KawarimiValidate < Formula
  desc "Fail on structural mock/scenario JSON issues that runtime only warns about."
  homepage "https://github.com/novr/Kawarimi"
  version "4.3.0"
  license "MIT"

  url "https://github.com/novr/Kawarimi/releases/download/v4.3.0/kawarimi-validate_4.3.0_darwin.tar.gz"
  sha256 "18e573aea4232d5328f35508b9b1a009fbf3823de2c017e5881eec1ae8ef20c2"
  depends_on :macos

  def install
    bin.install "kawarimi-validate"
  end

  test do
    output = shell_output("#{bin}/kawarimi-validate --help")
    assert_match "kawarimi-validate", output
  end
end
