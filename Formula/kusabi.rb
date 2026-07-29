    class Kusabi < Formula
      desc "Bind multiple Git repositories and aggregate context for agents"
      homepage "https://github.com/novr/kusabi"
      version "0.1.0"
      license "MIT"

      on_macos do
        url "https://github.com/novr/kusabi/releases/download/v0.1.0/kusabi_0.1.0_darwin.tar.gz"
        sha256 "b2d9b4a3ecf00405a7d6a8ef660a081f56f9ce887724d2bd47359abd5b94f5c1"
      end

      def install
        bin.install "kusabi", "ksb", "git-kusabi"
        generate_completions_from_executable(bin/"kusabi", shells: [:bash, :zsh, :fish], shell_parameter_format: :cobra)
      end

      test do
        output = shell_output("#{bin}/kusabi --help")
        assert_match "Kusabi declares", output
      end
    end
