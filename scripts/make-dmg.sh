#!/usr/bin/env bash
#
# Package ZTrackerMac.app into distributable .dmg files (T-174; dual-arch T-201).
#
# Builds a **dedicated native binary per architecture** (arm64 for Apple Silicon,
# x86_64 for Intel) — no universal/fat binary — and makes one drag-to-install disk
# image for each, with an Applications symlink. If a notarization keychain profile is
# provided, it also notarizes each .dmg and staples the ticket so Gatekeeper clears it
# offline.
#
# Usage:
#   scripts/make-dmg.sh                 # build + package BOTH arches (arm64 + x86_64)
#   scripts/make-dmg.sh arm64           # just Apple Silicon
#   scripts/make-dmg.sh x86_64          # just Intel
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

# Which arches to build. Default: both. Optional first arg restricts to one.
ARCHES=("arm64" "x86_64")
if [[ $# -ge 1 ]]; then ARCHES=("$1"); fi

# Human-friendly label for each arch, used in the DMG filename + volume name so a
# tester can tell at a glance which download they want.
label_for() {
    case "$1" in
        arm64)  echo "AppleSilicon" ;;
        x86_64) echo "Intel" ;;
        *)      echo "$1" ;;
    esac
}

mkdir -p dist

for ARCH in "${ARCHES[@]}"; do
    LABEL="$(label_for "$ARCH")"
    DMG="dist/ZTrackerMac-${VERSION}-${LABEL}.dmg"
    STAGE="$(mktemp -d)/dmg"

    echo "==> building the app ($ARCH / $LABEL)"
    scripts/build-app.sh release "$ARCH"

    echo "==> staging the disk image"
    mkdir -p "$STAGE"
    cp -R "$APP" "$STAGE/"
    ln -s /Applications "$STAGE/Applications"      # drag-to-install target

    echo "==> creating $DMG"
    rm -f "$DMG"
    hdiutil create -volname "Z-Tracker $VERSION ($LABEL)" -srcfolder "$STAGE" \
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

    # Sparkle appcast (T-211): EdDSA-sign the finished .dmg and emit a one-item per-arch feed.
    # The enclosure points at this version's GitHub release asset; the running app fetches the
    # appcast from `releases/latest/download/appcast-<arch>.xml` (see build-app.sh SUFEEDURL).
    # `sign_update` uses the private key stored in this machine's Keychain (generate_keys).
    SIGN_UPDATE="$(find .build -type f -name sign_update -path '*/artifacts/*' 2>/dev/null | head -1)"
    if [[ -n "$SIGN_UPDATE" ]]; then
        echo "==> signing the .dmg + writing the appcast"
        SIG_ATTRS="$("$SIGN_UPDATE" "$DMG")"    # → sparkle:edSignature="…" length="…"
        ENCLOSURE_URL="https://github.com/drewcurley/z-tracker-mac/releases/download/v${VERSION}/ZTrackerMac-${VERSION}-${LABEL}.dmg"
        APPCAST="dist/appcast-${ARCH}.xml"
        cat > "$APPCAST" <<APPCASTXML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>Z-Tracker ($LABEL)</title>
    <item>
      <title>Version $VERSION</title>
      <sparkle:version>$VERSION</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <enclosure url="$ENCLOSURE_URL" $SIG_ATTRS type="application/octet-stream" />
    </item>
  </channel>
</rss>
APPCASTXML
        echo "==> wrote $APPCAST"
    else
        echo "==> WARNING: sign_update not found — appcast not generated (run 'swift build' first)"
    fi

    echo "==> done: $DMG"
done
