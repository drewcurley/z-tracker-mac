#!/usr/bin/env bash
#
# Assemble ZTrackerMac.app from the SwiftPM build (T-136).
#
# macOS TCC won't grant microphone / speech access to a bare executable, so the
# voice feature needs a real .app bundle: an Info.plist with a stable bundle id and
# the usage-description strings, plus an (ad-hoc) code signature so TCC can attribute
# and remember the grant. This wraps `swift build`'s product into that bundle.
#
# Usage: scripts/build-app.sh [release|debug] [arm64|x86_64]
#   config: default release
#   arch:   default = the host arch (uname -m). Pass x86_64 to cross-build a dedicated
#           Intel binary from an Apple-Silicon machine (or arm64 the other way). Each build
#           is a *native* single-arch binary — no universal/fat binary, no perf compromise.
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${1:-release}"
ARCH="${2:-$(uname -m)}"
VERSION="$(tr -d '[:space:]' < VERSION)"
APP="ZTrackerMac.app"
EXE="ZTrackerMac"
RES_BUNDLE="ZTrackerMac_ZTrackerMac.bundle"
# Sparkle per-architecture appcast (T-211): each dedicated build updates to its own native
# binary. The `releases/latest/download/…` URL is a stable GitHub redirect to the newest
# release's asset, so no GitHub Pages / separate host is needed.
SUFEEDURL="https://github.com/drewcurley/z-tracker-mac/releases/latest/download/appcast-${ARCH}.xml"

echo "==> swift build -c $CONFIG --arch $ARCH"
swift build -c "$CONFIG" --arch "$ARCH"
BIN_DIR="$(swift build -c "$CONFIG" --arch "$ARCH" --show-bin-path)"

echo "==> assembling $APP (v$VERSION)"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN_DIR/$EXE" "$APP/Contents/MacOS/$EXE"
# The SwiftPM resource bundle goes in Contents/Resources — the standard place for a
# nested bundle, and where `Bundle.module` looks first (Bundle.main.resourceURL).
cp -R "$BIN_DIR/$RES_BUNDLE" "$APP/Contents/Resources/$RES_BUNDLE"

# SwiftPM's resource bundle ships as a flat folder with NO Info.plist. macOS 26 loads it
# anyway, but **macOS 15 (Sequoia) rejects a plist-less `.bundle` in `Bundle(url:)`**, so
# `Bundle.module` fatalErrors "unable to find bundle" at launch → SIGILL on first sprite
# load (T-202). Write a minimal old-style (flattened, resources-at-root) Info.plist so the
# bundle validates on every supported OS. Done *before* signing so the signature seals it.
RES_PLIST="$APP/Contents/Resources/$RES_BUNDLE/Info.plist"
if [ ! -f "$RES_PLIST" ]; then
    echo "==> adding Info.plist to the resource bundle (Sequoia Bundle(url:) fix)"
    cat > "$RES_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key><string>en</string>
    <key>CFBundleIdentifier</key><string>com.drewcurley.ztracker-mac.resources</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>CFBundleName</key><string>ZTrackerMac_ZTrackerMac</string>
    <key>CFBundlePackageType</key><string>BNDL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>$VERSION</string>
</dict>
</plist>
PLIST
fi

# Build stamp (T-179): git short hash (+ "-dirty" if the tree has uncommitted
# changes) and the build time, so the About window can prove the running app is the
# latest local build (a stale copy shows an older stamp).
GIT_HASH="$(git rev-parse --short HEAD 2>/dev/null || echo nogit)"
git diff --quiet 2>/dev/null && git diff --cached --quiet 2>/dev/null || GIT_HASH="${GIT_HASH}-dirty"
BUILD_STAMP="${GIT_HASH} · $(date '+%b %d %H:%M')"
sed -e "s/@@VERSION@@/$VERSION/g" -e "s/@@BUILD@@/$BUILD_STAMP/g" \
    -e "s|@@SUFEEDURL@@|$SUFEEDURL|g" \
    Bundle/Info.plist.template > "$APP/Contents/Info.plist"

# Embed Sparkle.framework (T-211): the SwiftPM build drops a universal (arm64+x86_64) copy in
# the bin dir; the standard home for it is Contents/Frameworks. Add an rpath there so the
# executable resolves it at runtime inside the bundle (the linker's build-dir rpath won't).
FW_SRC="$BIN_DIR/Sparkle.framework"
if [ -d "$FW_SRC" ]; then
    echo "==> embedding Sparkle.framework"
    mkdir -p "$APP/Contents/Frameworks"
    cp -R "$FW_SRC" "$APP/Contents/Frameworks/Sparkle.framework"
    install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP/Contents/MacOS/$EXE" 2>/dev/null || true
else
    echo "==> WARNING: Sparkle.framework not found at $FW_SRC — auto-update will be unavailable"
fi

# App icon (T-161/T-178): the **simple** icon is the default/bundle icon now
# (Bundle/AppIcon-simple.png, pre-rounded to the standard macOS shape via
# scripts/make-simple-icon.swift). Building the .icns from it means the simple icon
# shows reliably whether the app is open or closed, with no writable-location hack.
if [ -f Bundle/AppIcon-simple.png ]; then
    echo "==> building AppIcon.icns (simple, default)"
    ICONSET="$(mktemp -d)/AppIcon.iconset"
    mkdir -p "$ICONSET"
    for sz in 16 32 128 256 512; do
        sips -z "$sz" "$sz" Bundle/AppIcon-simple.png --out "$ICONSET/icon_${sz}x${sz}.png" >/dev/null
        d=$((sz * 2))
        sips -z "$d" "$d" Bundle/AppIcon-simple.png --out "$ICONSET/icon_${sz}x${sz}@2x.png" >/dev/null
    done
    iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
    rm -rf "$(dirname "$ICONSET")"
fi

# The alternate **detailed** icon (the original, more complex design) as a loadable
# resource, so the "Use detailed app icon" setting can swap to it for the running app.
if [ -f Bundle/AppIcon.png ]; then
    cp Bundle/AppIcon.png "$APP/Contents/Resources/AppIcon-detailed.png"
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
    ACTUAL_ID="$SIGN_ID"
else
    echo "==> '$SIGN_ID' not found; ad-hoc signing (TCC will re-prompt on each rebuild)"
    ACTUAL_ID="-"
fi
# Sign nested code (Sparkle.framework and its helpers) BEFORE the app, so the app's signature
# seals an already-valid framework (Apple discourages --deep on the app; --deep here just
# re-signs the vendored framework's own helpers with our identity). Hardened runtime only on a
# Developer ID (notarized) build.
FW="$APP/Contents/Frameworks/Sparkle.framework"
if [ -d "$FW" ]; then
    echo "==> signing Sparkle.framework as '$ACTUAL_ID'"
    if [[ "$ACTUAL_ID" == Developer\ ID\ Application* ]]; then
        codesign --force --deep --options runtime --timestamp --sign "$ACTUAL_ID" "$FW"
    else
        codesign --force --deep --sign "$ACTUAL_ID" "$FW"
    fi
fi
if [[ "$ACTUAL_ID" == Developer\ ID\ Application* ]]; then
    echo "==> code signing (hardened runtime) as '$ACTUAL_ID'"
    codesign --force --options runtime \
        --entitlements Bundle/ZTrackerMac.entitlements \
        --timestamp --sign "$ACTUAL_ID" "$APP"
else
    echo "==> code signing as '$ACTUAL_ID'"
    codesign --force --sign "$ACTUAL_ID" "$APP"
fi

echo "==> done: $APP (v$VERSION, $ARCH)"
echo "    run: open $APP    (or: $APP/Contents/MacOS/$EXE for console output)"
