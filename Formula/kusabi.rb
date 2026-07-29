    class Kusabi < Formula
      desc "Bind multiple Git repositories and aggregate context for agents"
      homepage "https://github.com/novr/kusabi"
  version "0.2.1"
      license "MIT"

      on_macos do
        url "https://github.com/novr/kusabi/releases/download/v0.2.1/kusabi_0.2.1_darwin.tar.gz"
        sha256 "ba4f528fd3cf00d266ed9a0d308c10d6c2ad9100532abb9744baf49b4aa408ce"
      end

      def install
        bin.install "kusabi"
        bin.install_symlink "kusabi" => "ksb"
        bin.install_symlink "kusabi" => "git-kusabi"
        generate_completions_from_executable(bin/"kusabi", shells: [:bash, :zsh, :fish], shell_parameter_format: :cobra)
      end

      test do
        output = shell_output("#{bin}/kusabi --help")
        assert_match "Kusabi declares", output
      end
    end
