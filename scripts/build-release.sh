#!/usr/bin/env bash
# Builds a Release Swapr.app and packages it as build/Swapr-<version>.zip.
# The app is ad-hoc signed with the hardened runtime; see docs/BUILDING.md for Developer ID signing.
set -euo pipefail

cd "$(dirname "$0")/.."
DERIVED_DATA="build/DerivedData"

xcodebuild \
  -project Swapr.xcodeproj \
  -scheme Swapr \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA" \
  build

APP="$DERIVED_DATA/Build/Products/Release/Swapr.app"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Contents/Info.plist")
ZIP="build/Swapr-$VERSION.zip"

codesign --verify --deep --strict "$APP"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
echo "Packaged $ZIP"
