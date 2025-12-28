cask "reflow" do
  version "0.2.0"
  sha256 "PLACEHOLDER_SHA256"

  url "https://github.com/OWNER/reflow/releases/download/v#{version}/Reflow-#{version}.dmg"
  name "Reflow"
  desc "macOS menu bar utility that unwraps hard-wrapped terminal text"
  homepage "https://github.com/OWNER/reflow"

  depends_on macos: ">= :sonoma"

  app "Reflow.app"

  zap trash: [
    "~/Library/Preferences/com.reflow.app.plist",
    "~/Library/Application Support/com.reflow.app",
  ]
end
