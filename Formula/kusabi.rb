    class Kusabi < Formula
      desc "Bind multiple Git repositories and aggregate context for agents"
      homepage "https://github.com/novr/kusabi"
  version "0.2.3"
      license "MIT"

      on_macos do
        url "https://github.com/novr/kusabi/releases/download/v0.2.3/kusabi_0.2.3_darwin.tar.gz"
        sha256 "0165aa8fe632beffd403378ef1377482d0086e4e0ba61bd9766134e35dacb00d"
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
