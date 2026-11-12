class Utsusemi < Formula
  desc "Ephemeral self-hosted GitHub Actions runners for Apple Silicon Macs"
  homepage "https://github.com/novr/Utsusemi"
  version "0.29.0"
  license "MIT"

  url "https://github.com/novr/Utsusemi/releases/download/v0.29.0/utsusemi_0.29.0_darwin.tar.gz"
  sha256 "751c88727ac7cf68232a3fb80a5d468a31a3b55f2cb308d99113f02661ee00b8"
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
