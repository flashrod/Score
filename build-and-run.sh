#!/bin/bash
set -euo pipefail

BUILD_DIR=".build/arm64-apple-macosx/debug"
APP_NAME="PremierLeagueBar"
PLIST="Sources/$APP_NAME/Resources/APIKeys.plist"

if [ ! -f "$PLIST" ]; then
    echo "❌ $PLIST not found"
    echo "   Copy APIKeys.plist.example to Sources/$APP_NAME/Resources/APIKeys.plist and add your key"
    exit 1
fi

KEY=$(plutil -extract FootballDataAPIKey raw -o - "$PLIST" 2>/dev/null || true)
if [ "$KEY" = "YOUR_API_KEY_HERE" ] || [ -z "$KEY" ]; then
    echo "❌ FootballDataAPIKey in $PLIST is empty or still set to the placeholder"
    echo "   Get a free key at https://www.football-data.org/ and add it to $PLIST"
    exit 1
fi

swift build

echo "✅ Built: $BUILD_DIR/$APP_NAME"

killall "$APP_NAME" 2>/dev/null || true

LAUNCH_CMD=("$BUILD_DIR/$APP_NAME")
if [ -n "${DEBUG_ANIMATIONS:-}" ]; then
    LAUNCH_CMD=(env DEBUG_ANIMATIONS="$DEBUG_ANIMATIONS" "${LAUNCH_CMD[@]}")
fi
nohup "${LAUNCH_CMD[@]}" </dev/null >/dev/null 2>&1 &
disown
echo "✅ Launched — look for the soccer ball in your menu bar"
