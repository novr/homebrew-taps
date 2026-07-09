cask "nyap" do
  version "0.0.3"
  sha256 "d6aa1ec31f481a32a3df0ed946e8f0d1beab2468168a8d20778855ee7b153fa5"

  url "https://github.com/novr/Nyap/releases/download/v#{version}/Nyap-macOS.zip",
      verified: "github.com/novr/Nyap/"
  name "Nyap"
  desc "Pomodoro timer with a cat overlay on breaks"
  homepage "https://github.com/novr/Nyap"

  depends_on macos: :sonoma

  app "Nyap.app"
end
