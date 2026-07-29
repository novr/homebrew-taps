    class Kusabi < Formula
      desc "Bind multiple Git repositories and aggregate context for agents"
      homepage "https://github.com/novr/kusabi"
  version "0.2.2"
      license "MIT"

      on_macos do
        url "https://github.com/novr/kusabi/releases/download/v0.2.2/kusabi_0.2.2_darwin.tar.gz"
        sha256 "1552afd3305b317b33afa12571c47df7e5eb5d338db4d39932162b6a30d79233"
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
