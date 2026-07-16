cask "top-score" do
  version "1.0.1"
  sha256 "089a1d92b62a580cc392293e2a56e20e284a431de1475b638ed0ac6b1872ff00"

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
