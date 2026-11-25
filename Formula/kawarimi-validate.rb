class KawarimiValidate < Formula
  desc "Fail on structural mock/scenario JSON issues that runtime only warns about."
  homepage "https://github.com/novr/Kawarimi"
  version "4.3.1"
  license "MIT"

  url "https://github.com/novr/Kawarimi/releases/download/v4.3.1/kawarimi-validate_4.3.1_darwin.tar.gz"
  sha256 "0935e91f96db47afc9d7549c9f76ce09fb20dbff4d916372670768277bfed759"
  depends_on :macos

  def install
    bin.install "kawarimi-validate"
  end

  test do
    output = shell_output("#{bin}/kawarimi-validate --help")
    assert_match "kawarimi-validate", output
  end
end
