cask "nyap" do
  version "0.0.1"
  sha256 "1b6d6e7a6db116abd2571649a9bd3f6bffe69ee6575d14c9a2b8f31f96afe7ca"

  url "https://github.com/novr/Nyap/releases/download/v#{version}/Nyap-macOS.zip",
      verified: "github.com/novr/Nyap/"
  name "Nyap"
  desc "Pomodoro timer with a cat overlay on breaks"
  homepage "https://github.com/novr/Nyap"

  depends_on macos: :sonoma

  app "Nyap.app"
end
