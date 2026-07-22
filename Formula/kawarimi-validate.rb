class KawarimiValidate < Formula
  desc "Fail on structural mock/scenario JSON issues that runtime only warns about."
  homepage "https://github.com/novr/Kawarimi"
  version "3.4.1"
  license "MIT"

  on_macos do
    url "https://github.com/novr/Kawarimi/releases/download/v3.4.1/kawarimi-validate_3.4.1_darwin.tar.gz"
    sha256 "e7c81d02d6de96505b8975cfb351f122e1616ef67be304c4e68cbe3cf08fcd3e"
  end

  def install
    bin.install "kawarimi-validate"
  end

  test do
    output = shell_output("#{bin}/kawarimi-validate --help")
    assert_match "kawarimi-validate", output
  end
end
