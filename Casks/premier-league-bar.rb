cask "premier-league-bar" do
  version "1.0"
  sha256 :no_check

  url "https://github.com/flashrod/Score/releases/download/v#{version}/PremierLeagueBar-#{version}.dmg"
  name "Premier League Bar"
  desc "Live Premier League scores and standings in your menu bar"
  homepage "https://github.com/flashrod/Score"

  auto_updates false

  app "PremierLeagueBar.app"

  uninstall quit: "com.dylanmascarenhas.PremierLeagueBar"

  zap trash: [
    "~/Library/Preferences/com.dylanmascarenhas.PremierLeagueBar.plist",
  ]
end
