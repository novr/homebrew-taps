class KawarimiValidate < Formula
  desc "Fail on structural mock/scenario JSON issues that runtime only warns about."
  homepage "https://github.com/novr/Kawarimi"
  version "4.2.0"
  license "MIT"

  url "https://github.com/novr/Kawarimi/releases/download/v4.2.0/kawarimi-validate_4.2.0_darwin.tar.gz"
  sha256 "7529b15ab05c89322a648a49bd1cd99f7847e919377abccf60a06eb217d82dda"
  depends_on :macos

  def install
    bin.install "kawarimi-validate"
  end

  test do
    output = shell_output("#{bin}/kawarimi-validate --help")
    assert_match "kawarimi-validate", output
  end
end
