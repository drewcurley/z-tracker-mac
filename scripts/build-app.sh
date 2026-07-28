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

# App icon (T-161): build AppIcon.icns from the transparent-corner master
# (Bundle/AppIcon.png). macOS shows app icons as-is (no auto-rounding), so the
# master already has its rounded panel on a transparent field.
if [ -f Bundle/AppIcon.png ]; then
    echo "==> building AppIcon.icns"
    ICONSET="$(mktemp -d)/AppIcon.iconset"
    mkdir -p "$ICONSET"
    for sz in 16 32 128 256 512; do
        sips -z "$sz" "$sz" Bundle/AppIcon.png --out "$ICONSET/icon_${sz}x${sz}.png" >/dev/null
        d=$((sz * 2))
        sips -z "$d" "$d" Bundle/AppIcon.png --out "$ICONSET/icon_${sz}x${sz}@2x.png" >/dev/null
    done
    iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
    rm -rf "$(dirname "$ICONSET")"
fi

# Alternate "simple" app icon (T-178): copied as a loadable resource so the
# "Use simple app icon" setting can swap the dock icon at runtime (the .icns above
# stays the original/default).
if [ -f Bundle/simple.png ]; then
    cp Bundle/simple.png "$APP/Contents/Resources/AppIcon-simple.png"
fi

# Sign with a STABLE identity so TCC (mic/speech permission) persists across rebuilds.
# A self-signed "ZTracker Dev" code-signing cert gives a stable designated requirement
# — unlike ad-hoc (--sign -), whose identity is the ever-changing binary hash, which
# made macOS re-prompt on every rebuild. Falls back to ad-hoc if the cert is absent.
# (The SwiftPM resource bundle is a flat asset folder with no Info.plist, so it is not
# a signable code bundle — don't --deep into it; signing the app seals it as a resource.)
#
# For a distributable (notarized) build, set ZTRACKER_SIGN_ID to a "Developer ID
# Application: …" identity — the script then adds the hardened runtime + entitlements
# that notarization requires. Any other identity (the default self-signed dev cert)
# signs without the hardened runtime, which is what local dev + TCC want.
SIGN_ID="${ZTRACKER_SIGN_ID:-ZTracker Dev}"
if security find-identity -p codesigning 2>/dev/null | grep -q "$SIGN_ID"; then
    if [[ "$SIGN_ID" == Developer\ ID\ Application* ]]; then
        echo "==> code signing (hardened runtime) as '$SIGN_ID'"
        codesign --force --options runtime \
            --entitlements Bundle/ZTrackerMac.entitlements \
            --timestamp --sign "$SIGN_ID" "$APP"
    else
        echo "==> code signing as '$SIGN_ID'"
        codesign --force --sign "$SIGN_ID" "$APP"
    fi
else
    echo "==> '$SIGN_ID' not found; ad-hoc signing (TCC will re-prompt on each rebuild)"
    codesign --force --sign - "$APP"
fi

echo "==> done: $APP (v$VERSION)"
echo "    run: open $APP    (or: $APP/Contents/MacOS/$EXE for console output)"
