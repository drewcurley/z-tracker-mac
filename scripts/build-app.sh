#!/usr/bin/env bash
#
# Assemble ZTrackerMac.app from the SwiftPM build (T-136).
#
# macOS TCC won't grant microphone / speech access to a bare executable, so the
# voice feature needs a real .app bundle: an Info.plist with a stable bundle id and
# the usage-description strings, plus an (ad-hoc) code signature so TCC can attribute
# and remember the grant. This wraps `swift build`'s product into that bundle.
#
# Usage: scripts/build-app.sh [release|debug]   (default: release)
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${1:-release}"
VERSION="$(tr -d '[:space:]' < VERSION)"
APP="ZTrackerMac.app"
EXE="ZTrackerMac"
RES_BUNDLE="ZTrackerMac_ZTrackerMac.bundle"

echo "==> swift build -c $CONFIG"
swift build -c "$CONFIG"
BIN_DIR="$(swift build -c "$CONFIG" --show-bin-path)"

echo "==> assembling $APP (v$VERSION)"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN_DIR/$EXE" "$APP/Contents/MacOS/$EXE"
# The SwiftPM resource bundle goes in Contents/Resources — the standard place for a
# nested bundle, and where `Bundle.module` looks first (Bundle.main.resourceURL).
cp -R "$BIN_DIR/$RES_BUNDLE" "$APP/Contents/Resources/$RES_BUNDLE"

sed "s/@@VERSION@@/$VERSION/g" Bundle/Info.plist.template > "$APP/Contents/Info.plist"

echo "==> ad-hoc code signing"
# The SwiftPM resource bundle is a flat asset folder with no Info.plist, so it is
# NOT a signable code bundle — don't --deep into it (that errors). Signing the app
# alone seals it as a sealed resource, and gives the app the stable ad-hoc identity
# TCC needs to remember the mic/speech grant.
codesign --force --sign - "$APP"

echo "==> done: $APP (v$VERSION)"
echo "    run: open $APP    (or: $APP/Contents/MacOS/$EXE for console output)"
