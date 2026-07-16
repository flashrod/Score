cask "premier-league-bar" do
  version "1.0.1"
  sha256 "3f8ed05b73aa22457dd8affe0fad8dc7b74cfd7b9d5dd7b7bf1ece0b6c891aa9"

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
