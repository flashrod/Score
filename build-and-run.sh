#!/bin/bash
set -euo pipefail

BUILD_DIR=".build/arm64-apple-macosx/debug"
APP_NAME="PremierLeagueBar"

if [ -z "${FOOTBALL_DATA_API_KEY:-}" ]; then
    echo "❌ FOOTBALL_DATA_API_KEY not set"
    echo "   export FOOTBALL_DATA_API_KEY=your_key"
    exit 1
fi

swift build
mkdir -p "$BUILD_DIR/$APP_NAME.app/Contents/MacOS"
cp "$BUILD_DIR/$APP_NAME" "$BUILD_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME"
cp "Sources/$APP_NAME/Info.plist" "$BUILD_DIR/$APP_NAME.app/Contents"

echo "✅ Built: $BUILD_DIR/$APP_NAME.app"

# Kill existing instance if running
killall "$APP_NAME" 2>/dev/null || true

# Launch with env var
FOOTBALL_DATA_API_KEY="$FOOTBALL_DATA_API_KEY" \
    "$BUILD_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME" &
disown
echo "✅ Launched — look for the soccer ball in your menu bar"
