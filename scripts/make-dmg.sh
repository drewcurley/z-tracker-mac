#!/usr/bin/env bash
#
# Package ZTrackerMac.app into a distributable .dmg (T-174).
#
# Builds the app (via build-app.sh), then makes a drag-to-install disk image with an
# Applications symlink. If a notarization keychain profile is provided, it also
# notarizes the .dmg and staples the ticket so Gatekeeper clears it offline.
#
# Usage:
#   scripts/make-dmg.sh                     # build + package (dev-signed or unsigned)
#   ZTRACKER_SIGN_ID="Developer ID Application: Name (TEAMID)" \
#     ZTRACKER_NOTARY_PROFILE="ztracker-notary" scripts/make-dmg.sh   # + notarize
#
# For notarization, store credentials once with:
#   xcrun notarytool store-credentials ztracker-notary \
#     --apple-id you@example.com --team-id TEAMID --password <app-specific-password>
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="$(tr -d '[:space:]' < VERSION)"
APP="ZTrackerMac.app"
DMG="dist/ZTrackerMac-${VERSION}.dmg"
STAGE="$(mktemp -d)/dmg"

echo "==> building the app"
scripts/build-app.sh release

echo "==> staging the disk image"
mkdir -p "$STAGE" dist
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"      # drag-to-install target

echo "==> creating $DMG"
rm -f "$DMG"
hdiutil create -volname "Z-Tracker $VERSION" -srcfolder "$STAGE" \
    -ov -format UDZO "$DMG" >/dev/null
rm -rf "$(dirname "$STAGE")"

# Notarize only when a keychain profile is supplied (a Developer ID build).
if [[ -n "${ZTRACKER_NOTARY_PROFILE:-}" ]]; then
    echo "==> notarizing (profile: $ZTRACKER_NOTARY_PROFILE)"
    xcrun notarytool submit "$DMG" --keychain-profile "$ZTRACKER_NOTARY_PROFILE" --wait
    echo "==> stapling the ticket"
    xcrun stapler staple "$DMG"
else
    echo "==> skipping notarization (set ZTRACKER_NOTARY_PROFILE to enable)"
fi

echo "==> done: $DMG"
