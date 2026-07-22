#!/bin/bash
set -euo pipefail

APP_NAME="TopScore"
BUNDLE_ID="com.dylanmascarenhas.TopScore"
VERSION="1.1.0"

ARCH=$(uname -m)
BUILD_DIR=".build/${ARCH}-apple-macosx/release"
RELEASE_DIR=".release"
APP_BUNDLE="$RELEASE_DIR/$APP_NAME.app"
DMG_PATH="$RELEASE_DIR/$APP_NAME-$VERSION.dmg"
STAGING_DIR="$RELEASE_DIR/staging"

echo "==> Building binary for $ARCH (release)..."
swift build -c release

echo "==> Creating .app bundle..."
rm -rf "$RELEASE_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "Sources/TopScore/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

if [ -d "Sources/TopScore/Resources" ]; then
  cp -r "Sources/TopScore/Resources/" "$APP_BUNDLE/Contents/Resources/"
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
