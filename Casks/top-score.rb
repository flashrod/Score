cask "top-score" do
  version "1.0.1"
  sha256 "44111e83eb46cc12380c4af82d41b5b059c1a0d6eaacc5bc0f22cbd177f3f345"

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
