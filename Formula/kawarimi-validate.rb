class KawarimiValidate < Formula
  desc "Fail on structural mock/scenario JSON issues that runtime only warns about."
  homepage "https://github.com/novr/Kawarimi"
  version "3.4.0"
  license "MIT"

  on_macos do
    url "https://github.com/novr/Kawarimi/releases/download/v3.4.0/kawarimi-validate_3.4.0_darwin.tar.gz"
    sha256 "56d5d1550274ab94464a8f3fcb90055d0f615b3d13a43ff308efcca0f1e63b42"
  end

  def install
    bin.install "kawarimi-validate"
  end

  test do
    output = shell_output("#{bin}/kawarimi-validate --help")
    assert_match "kawarimi-validate", output
  end
end
