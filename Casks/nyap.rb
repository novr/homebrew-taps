cask "nyap" do
  version "0.0.5"
  sha256 "0daf163e6d32fb443aa8855aca0a5ca72e25259eca69d712fb0aab1c9658906f"

  url "https://github.com/novr/Nyap/releases/download/v#{version}/Nyap-macOS.zip",
      verified: "github.com/novr/Nyap/"
  name "Nyap"
  desc "Pomodoro timer with a cat overlay on breaks"
  homepage "https://github.com/novr/Nyap"

  depends_on macos: :sonoma

  app "Nyap.app"
end
