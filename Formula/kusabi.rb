    class Kusabi < Formula
      desc "Bind multiple Git repositories and aggregate context for agents"
      homepage "https://github.com/novr/kusabi"
  version "0.2.5"
      license "MIT"

      on_macos do
        url "https://github.com/novr/kusabi/releases/download/v0.2.5/kusabi_0.2.5_darwin.tar.gz"
        sha256 "b6164042f89d6f605f275398ce2c940863126edf21d86549da0cf0a7e2bde835"
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
