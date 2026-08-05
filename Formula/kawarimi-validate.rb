class KawarimiValidate < Formula
  desc "Fail on structural mock/scenario JSON issues that runtime only warns about."
  homepage "https://github.com/novr/Kawarimi"
  version "4.1.0"
  license "MIT"

  on_macos do
    url "https://github.com/novr/Kawarimi/releases/download/v4.1.0/kawarimi-validate_4.1.0_darwin.tar.gz"
    sha256 "d00624ed7f02743f8981409a1b4a7d51347056d392f0ae33e4ee16dbddf07808"
  end

  def install
    bin.install "kawarimi-validate"
  end

  test do
    output = shell_output("#{bin}/kawarimi-validate --help")
    assert_match "kawarimi-validate", output
  end
end
