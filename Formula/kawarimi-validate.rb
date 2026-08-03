class KawarimiValidate < Formula
  desc "Fail on structural mock/scenario JSON issues that runtime only warns about."
  homepage "https://github.com/novr/Kawarimi"
  version "4.0.0"
  license "MIT"

  on_macos do
    url "https://github.com/novr/Kawarimi/releases/download/v4.0.0/kawarimi-validate_4.0.0_darwin.tar.gz"
    sha256 "7991fdf40a04a52659bbd419be9755725c1c11a5719e1efe098b04182d5876d2"
  end

  def install
    bin.install "kawarimi-validate"
  end

  test do
    output = shell_output("#{bin}/kawarimi-validate --help")
    assert_match "kawarimi-validate", output
  end
end
