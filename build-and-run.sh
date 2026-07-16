#!/bin/bash
set -euo pipefail

BUILD_DIR=".build/arm64-apple-macosx/debug"
APP_NAME="TopScore"

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
