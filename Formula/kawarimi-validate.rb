class KawarimiValidate < Formula
  desc "Fail on structural mock/scenario JSON issues that runtime only warns about."
  homepage "https://github.com/novr/Kawarimi"
  version "3.3.5"
  license "MIT"

  on_macos do
    url "https://github.com/novr/Kawarimi/releases/download/v3.3.5/kawarimi-validate_3.3.5_darwin.tar.gz"
    sha256 "6afad320534aede820ec1afe9a52cfa5dae9855f2000e28c3adf0e1bcd82350f"
  end

  def install
    bin.install "kawarimi-validate"
  end

  test do
    output = shell_output("#{bin}/kawarimi-validate --help")
    assert_match "kawarimi-validate", output
  end
end
