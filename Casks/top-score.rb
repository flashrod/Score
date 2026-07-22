cask "top-score" do
  version "1.1.0"
  sha256 "f11cafb1b552977a3091429b00095777b07de7ff14995ad2e48a911faa472582"

  url "https://github.com/flashrod/Score/releases/download/v#{version}/TopScore-#{version}.dmg"
  name "TopScore"
  desc "Live Premier League scores in your macOS menu bar"
  homepage "https://github.com/flashrod/Score"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates false

  app "TopScore.app"

  uninstall quit: "com.dylanmascarenhas.TopScore"

  zap trash: [
    "~/Library/Preferences/com.dylanmascarenhas.TopScore.plist",
  ]
end
