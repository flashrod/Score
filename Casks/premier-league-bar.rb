cask "premier-league-bar" do
  version "1.0.1"
  sha256 "c1fd3ec045234ca8c1a4f8e99e2d29374ddbf84e0edb509848750cadfd4a8fca"

  url "https://github.com/flashrod/Score/releases/download/v#{version}/PremierLeagueBar-#{version}.dmg"
  name "Premier League Bar"
  desc "Live Premier League scores in your macOS menu bar"
  homepage "https://github.com/flashrod/Score"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates false

  app "PremierLeagueBar.app"

  uninstall quit: "com.dylanmascarenhas.PremierLeagueBar"

  zap trash: [
    "~/Library/Preferences/com.dylanmascarenhas.PremierLeagueBar.plist",
  ]
end
