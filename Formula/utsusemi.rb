class Utsusemi < Formula
  desc "Ephemeral self-hosted GitHub Actions runners for Apple Silicon Macs"
  homepage "https://github.com/novr/Utsusemi"
  version "0.31.1"
  license "MIT"

  url "https://github.com/novr/Utsusemi/releases/download/v0.31.1/utsusemi_0.31.1_darwin.tar.gz"
  sha256 "8d90bf11edfa0da297939acff6d8b4011c31c4ad53f2063b93324cb245fe3d29"
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
