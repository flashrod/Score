cask "top-score" do
  version "1.0.1"
  sha256 "732ee799c02d7de497d2ce5d0a1d5a28c0b3b65d736024aef6653627ec9dd1f0"

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
