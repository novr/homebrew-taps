    class Kusabi < Formula
      desc "Bind multiple Git repositories and aggregate context for agents"
      homepage "https://github.com/novr/kusabi"
  version "0.2.0"
      license "MIT"

      on_macos do
        url "https://github.com/novr/kusabi/releases/download/v0.2.0/kusabi_0.2.0_darwin.tar.gz"
        sha256 "60bbb637f3977bfc956a67e895223bbe405eb1e04cf51efe182c4f3e18f14f44"
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
