#!/bin/bash
set -euo pipefail

APP_NAME="PremierLeagueBar"
BUNDLE_ID="com.dylanmascarenhas.PremierLeagueBar"
VERSION="1.0"

ARCH=$(uname -m)
BUILD_DIR=".build/${ARCH}-apple-macosx/release"
RELEASE_DIR=".release"
APP_BUNDLE="$RELEASE_DIR/$APP_NAME.app"
DMG_PATH="$RELEASE_DIR/$APP_NAME-$VERSION.dmg"
STAGING_DIR="$RELEASE_DIR/staging"

echo "==> Building release binary for $ARCH..."
swift build -c release

echo "==> Creating .app bundle..."
rm -rf "$RELEASE_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "Sources/$APP_NAME/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

if [ -d "Sources/$APP_NAME/Resources" ]; then
  cp -r "Sources/$APP_NAME/Resources/" "$APP_BUNDLE/Contents/Resources/"
fi

echo "==> Signing app (ad-hoc)..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "==> Creating DMG..."
mkdir -p "$STAGING_DIR"
cp -R "$APP_BUNDLE" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

rm -f "$DMG_PATH"
hdiutil create -volname "Premier League Bar $VERSION" \
  -srcfolder "$STAGING_DIR" \
  -ov -format UDZO \
  "$DMG_PATH"

rm -rf "$STAGING_DIR"

echo "✅ Done: $DMG_PATH ($(du -sh "$DMG_PATH" | cut -f1))"
