class Utsusemi < Formula
  desc "Ephemeral self-hosted GitHub Actions runners for Apple Silicon Macs"
  homepage "https://github.com/novr/Utsusemi"
  version "0.31.0"
  license "MIT"

  url "https://github.com/novr/Utsusemi/releases/download/v0.31.0/utsusemi_0.31.0_darwin.tar.gz"
  sha256 "203206573ba2c8e3247a1faeb01d786d8ae071253f0bac39f41a1a26aa4d396a"
  depends_on :macos

  def install
    bin.install "utsusemi"
    generate_completions_from_executable(bin/"utsusemi", shell_parameter_format: :cobra)
  end

  service do
    run [opt_bin/"utsusemi", "run", "--log"]
    keep_alive true
    log_path var/"log/utsusemi.log"
    error_log_path var/"log/utsusemi.error.log"
    environment_variables PATH: std_service_path_env
  end
  test do
    output = shell_output("#{bin}/utsusemi --help")
    assert_match "Ephemeral self-hosted", output
  end
end
