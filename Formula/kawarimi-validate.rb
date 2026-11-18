class KawarimiValidate < Formula
  desc "Fail on structural mock/scenario JSON issues that runtime only warns about."
  homepage "https://github.com/novr/Kawarimi"
  version "4.2.1"
  license "MIT"

  url "https://github.com/novr/Kawarimi/releases/download/v4.2.1/kawarimi-validate_4.2.1_darwin.tar.gz"
  sha256 "fc3e14bc5ef6b34ee2b3f64e5c3085c2b64e0b66c99fd68e7d970eec2f363f4c"
  depends_on :macos

  def install
    bin.install "kawarimi-validate"
  end

  test do
    output = shell_output("#{bin}/kawarimi-validate --help")
    assert_match "kawarimi-validate", output
  end
end
