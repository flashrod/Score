cask "top-score" do
  version "1.0.1"
  sha256 "0f3cd823e17f2859e7a63092fb2cafcbac749d4a51708f72606d372a46413fbd"

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
