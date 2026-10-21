    class Kusabi < Formula
      desc "Bind multiple Git repositories and aggregate context for agents"
      homepage "https://github.com/novr/kusabi"
  version "0.2.6"
      license "MIT"

      on_macos do
        url "https://github.com/novr/kusabi/releases/download/v0.2.6/kusabi_0.2.6_darwin.tar.gz"
        sha256 "3fda0cb9e896265474a0781b701337e646c42d4b75f6feae40be701fef5be82a"
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
