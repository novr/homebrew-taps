class Utsusemi < Formula
  desc "Ephemeral self-hosted GitHub Actions runners for Apple Silicon Macs"
  homepage "https://github.com/novr/Utsusemi"
  version "0.30.0"
  license "MIT"

  url "https://github.com/novr/Utsusemi/releases/download/v0.30.0/utsusemi_0.30.0_darwin.tar.gz"
  sha256 "d4c73b871dea6c3510dcbb26061f3f8eab97c2d3f2dc2c7e6a5edbd001270755"
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
