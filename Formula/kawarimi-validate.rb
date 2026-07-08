class KawarimiValidate < Formula
  desc "Fail on structural mock/scenario JSON issues that runtime only warns about."
  homepage "https://github.com/novr/Kawarimi"
  version "3.3.4"
  license "MIT"

  on_macos do
    url "https://github.com/novr/Kawarimi/releases/download/v3.3.4/kawarimi-validate_3.3.4_darwin.tar.gz"
    sha256 "3fc246d52fc66d7dcaa4600fbd34b3d31a932d4f796ae99e9e3dc654bfb07c7e"
  end

  def install
    bin.install "kawarimi-validate"
  end

  test do
    output = shell_output("#{bin}/kawarimi-validate --help")
    assert_match "kawarimi-validate", output
  end
end
