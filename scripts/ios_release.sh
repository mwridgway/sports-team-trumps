#!/usr/bin/env bash
# Build URC Trumps and upload it to TestFlight.
# Needs: Xcode 26, xcodegen, the game data in ios/URCTrumps/Resources/GameData (scripts/pull_app_data.py, or
# scripts/export_app_data.py after a local ingest) and an App Store Connect
# API key with the Admin role: ASC_KEY_ID, ASC_ISSUER_ID and ASC_KEY_PATH (path to the .p8).
# BUILD_NUMBER defaults to a UTC timestamp so every upload is unique.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
: "${ASC_KEY_ID:?}" "${ASC_ISSUER_ID:?}" "${ASC_KEY_PATH:?}"
BUILD_NUMBER="${BUILD_NUMBER:-$(date -u +%Y%m%d%H%M)}"
BUILD_DIR="$ROOT/ios/build"
AUTH=(-allowProvisioningUpdates
  -authenticationKeyPath "$ASC_KEY_PATH"
  -authenticationKeyID "$ASC_KEY_ID"
  -authenticationKeyIssuerID "$ASC_ISSUER_ID")

test -f "$ROOT/ios/URCTrumps/Resources/GameData/urc.json" || { echo "No game data: run scripts/pull_app_data.py" >&2; exit 1; }
(cd "$ROOT/ios" && xcodegen generate)
rm -rf "$BUILD_DIR/URCTrumps.xcarchive" "$BUILD_DIR/export"

# Archive unsigned; the export below signs it with a cloud-managed Apple Distribution certificate,
# so CI never has to create or store signing certificates.
xcodebuild -project "$ROOT/ios/URCTrumps.xcodeproj" -scheme URCTrumps -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$BUILD_DIR/URCTrumps.xcarchive" \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" CODE_SIGNING_ALLOWED=NO archive

xcodebuild -exportArchive -archivePath "$BUILD_DIR/URCTrumps.xcarchive" \
  -exportOptionsPlist "$ROOT/ios/ExportOptions.plist" -exportPath "$BUILD_DIR/export" "${AUTH[@]}"

echo "Uploaded URC Trumps build $BUILD_NUMBER to App Store Connect"
