cask "nyap" do
  version "0.0.2"
  sha256 "46871adef4163167bad734f25a01281986eaa920ea231e0b245fc25dcfc95c05"

  url "https://github.com/novr/Nyap/releases/download/v#{version}/Nyap-macOS.zip",
      verified: "github.com/novr/Nyap/"
  name "Nyap"
  desc "Pomodoro timer with a cat overlay on breaks"
  homepage "https://github.com/novr/Nyap"

  depends_on macos: :sonoma

  app "Nyap.app"
end
