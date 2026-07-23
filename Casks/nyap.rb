cask "nyap" do
  version "0.0.4"
  sha256 "edb5c5726b2ac155089e6be7b955557dd40be931551ab4c6e90eac7db30cb3e2"

  url "https://github.com/novr/Nyap/releases/download/v#{version}/Nyap-macOS.zip",
      verified: "github.com/novr/Nyap/"
  name "Nyap"
  desc "Pomodoro timer with a cat overlay on breaks"
  homepage "https://github.com/novr/Nyap"

  depends_on macos: :sonoma

  app "Nyap.app"
end
