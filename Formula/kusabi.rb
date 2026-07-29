    class Kusabi < Formula
      desc "Bind multiple Git repositories and aggregate context for agents"
      homepage "https://github.com/novr/kusabi"
  version "0.2.4"
      license "MIT"

      on_macos do
        url "https://github.com/novr/kusabi/releases/download/v0.2.4/kusabi_0.2.4_darwin.tar.gz"
        sha256 "2f8405a6ec585bd102cb1f53bee6a9e511bec4015e2d77c7e3fd9f9f37f2e6b2"
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
