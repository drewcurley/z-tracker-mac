#!/usr/bin/env bash
#
# Package ZTrackerMac.app into distributable .dmg files (T-174; dual-arch T-201; hardened T-242).
#
# Builds a **dedicated native binary per architecture** (arm64 for Apple Silicon,
# x86_64 for Intel) — no universal/fat binary — and makes one drag-to-install disk
# image for each, with an Applications symlink. Each .dmg is code-signed, notarized,
# stapled, verified, and then EdDSA-signed into a one-item per-arch Sparkle appcast.
#
# Usage:
#   scripts/make-dmg.sh                 # build + package BOTH arches (arm64 + x86_64)
#   scripts/make-dmg.sh arm64           # just Apple Silicon
#   scripts/make-dmg.sh x86_64          # just Intel (e.g. to redo one arch after a failure)
#
# Required for a release (checked up front, before anything is built):
#   ZTRACKER_SIGN_ID="Developer ID Application: Name (TEAMID)"
#   …plus notarization credentials, either a keychain profile:
#     ZTRACKER_NOTARY_PROFILE="ztracker-notary"
#       (create once: xcrun notarytool store-credentials ztracker-notary \
#          --apple-id you@example.com --team-id TEAMID --password <app-specific-password>)
#   …or an App Store Connect API key (a file on disk — can't vanish from the keychain):
#     ZTRACKER_NOTARY_KEY=/path/AuthKey_XXXX.p8 ZTRACKER_NOTARY_KEY_ID=XXXX ZTRACKER_NOTARY_ISSUER=<uuid>
#
# Escape hatches (local testing only — never for a published release):
#   ZTRACKER_ALLOW_UNSIGNED=1   package without signing/notarizing; no appcast is written
#   ZTRACKER_ALLOW_DIRTY=1      allow uncommitted changes in the working tree
#
# Failure safety: each arch is built into dist/.staging and only moved into dist/ once it is
# signed, notarized, stapled and validated, so a mid-run failure never leaves an unnotarized
# DMG under its release name or a previous version's appcast beside a new DMG. The
# project-root app is always restored to the host arch on exit (success or failure).
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="$(tr -d '[:space:]' < VERSION)"
APP="ZTrackerMac.app"
REPO_URL="https://github.com/drewcurley/z-tracker-mac"
HOST_ARCH="$(uname -m)"
ALLOW_UNSIGNED="${ZTRACKER_ALLOW_UNSIGNED:-}"
# The minimum macOS, read from the bundle template so the appcast can't drift from the app.
MIN_OS="$(grep -A1 LSMinimumSystemVersion Bundle/Info.plist.template | sed -n 's:.*<string>\(.*\)</string>.*:\1:p' | head -1)"
MIN_OS="${MIN_OS:-14.0}"

# Which arches to build. Default: both. Optional first arg restricts to one.
ARCHES=("arm64" "x86_64")
if [[ $# -ge 1 ]]; then ARCHES=("$1"); fi

die() { echo "==> ERROR: $*" >&2; exit 1; }

# Human-friendly label for each arch, used in the DMG filename + volume name so a
# tester can tell at a glance which download they want.
label_for() {
    case "$1" in
        arm64)  echo "AppleSilicon" ;;
        x86_64) echo "Intel" ;;
        *)      echo "$1" ;;
    esac
}

# ---------------------------------------------------------------------------------------------
# Preflight — fail before spending 10 minutes building (T-242).
# ---------------------------------------------------------------------------------------------
NOTARY_ARGS=()
SIGN_UPDATE=""
if [[ -z "$ALLOW_UNSIGNED" ]]; then
    echo "==> preflight"
    [[ "${ZTRACKER_SIGN_ID:-}" == Developer\ ID\ Application* ]] \
        || die "ZTRACKER_SIGN_ID must be a 'Developer ID Application: …' identity (set ZTRACKER_ALLOW_UNSIGNED=1 for a local test package)."
    security find-identity -v -p codesigning 2>/dev/null | grep -qF "$ZTRACKER_SIGN_ID" \
        || die "signing identity not found in the keychain: $ZTRACKER_SIGN_ID"
    if [[ -n "${ZTRACKER_NOTARY_KEY:-}" ]]; then
        [[ -f "$ZTRACKER_NOTARY_KEY" && -n "${ZTRACKER_NOTARY_KEY_ID:-}" && -n "${ZTRACKER_NOTARY_ISSUER:-}" ]] \
            || die "ZTRACKER_NOTARY_KEY needs ZTRACKER_NOTARY_KEY_ID and ZTRACKER_NOTARY_ISSUER, and the .p8 must exist."
        NOTARY_ARGS=(--key "$ZTRACKER_NOTARY_KEY" --key-id "$ZTRACKER_NOTARY_KEY_ID" --issuer "$ZTRACKER_NOTARY_ISSUER")
    elif [[ -n "${ZTRACKER_NOTARY_PROFILE:-}" ]]; then
        NOTARY_ARGS=(--keychain-profile "$ZTRACKER_NOTARY_PROFILE")
    else
        die "no notarization credentials: set ZTRACKER_NOTARY_PROFILE, or ZTRACKER_NOTARY_KEY/_KEY_ID/_ISSUER."
    fi
    xcrun notarytool history "${NOTARY_ARGS[@]}" >/dev/null 2>&1 \
        || die "notarization credentials don't work (a keychain profile can go missing — re-run 'xcrun notarytool store-credentials', or use the .p8 API key option)."
    if [[ -z "${ZTRACKER_ALLOW_DIRTY:-}" ]]; then
        git diff --quiet && git diff --cached --quiet \
            || die "uncommitted changes in the working tree — commit first (or ZTRACKER_ALLOW_DIRTY=1 for testing)."
    fi
    swift package resolve >/dev/null
    SIGN_UPDATE="$(find .build -type f -name sign_update -path '*/artifacts/*' 2>/dev/null | head -1)"
    [[ -n "$SIGN_UPDATE" ]] || die "Sparkle's sign_update tool not found under .build (run 'swift build' once)."
    echo "    identity, notary credentials, sign_update, clean tree: OK"
else
    echo "==> ZTRACKER_ALLOW_UNSIGNED=1 — local test package: no signing, no notarization, no appcast"
fi

# ---------------------------------------------------------------------------------------------
# Always leave ./ZTrackerMac.app native to this machine — even when a step fails (T-231/T-242).
# ---------------------------------------------------------------------------------------------
LAST_BUILT_ARCH=""
restore_host_app() {
    local status=$?
    if [[ -n "$LAST_BUILT_ARCH" && "$LAST_BUILT_ARCH" != "$HOST_ARCH" ]]; then
        echo "==> restoring project-root app to host arch ($HOST_ARCH) so ./ZTrackerMac.app stays native"
        scripts/build-app.sh release "$HOST_ARCH" || echo "==> WARNING: couldn't restore the host-arch app" >&2
    fi
    rm -rf dist/.staging
    exit "$status"
}
trap restore_host_app EXIT

# The release notes for $VERSION from CHANGELOG.md, as simple HTML for the appcast <description>
# (so Sparkle shows what changed). Empty if the section is missing.
release_notes_html() {
    python3 - "$VERSION" <<'PY' 2>/dev/null || true
import html, re, sys
version = sys.argv[1]
try:
    text = open("CHANGELOG.md", encoding="utf-8").read()
except OSError:
    sys.exit(0)
m = re.search(r"^## \[" + re.escape(version) + r"\][^\n]*\n(.*?)(?=^## \[|\Z)", text, re.S | re.M)
if not m:
    sys.exit(0)
def inline(s):
    s = html.escape(s)
    s = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", s)
    s = re.sub(r"`(.+?)`", r"<code>\1</code>", s)
    return s
out, items = [], []
def flush():
    if items:
        out.append("<ul>" + "".join(f"<li>{inline(i)}</li>" for i in items) + "</ul>")
        items.clear()
for line in m.group(1).splitlines():
    if line.startswith("### "):
        flush(); out.append(f"<h3>{inline(line[4:].strip())}</h3>")
    elif line.startswith("- "):
        items.append(line[2:].strip())
    elif line.startswith("  ") and items:
        items[-1] += " " + line.strip()
    elif line.strip():
        flush(); out.append(f"<p>{inline(line.strip())}</p>")
flush()
print("".join(out).replace("]]>", "]]&gt;"))
PY
}

mkdir -p dist dist/.staging

for ARCH in "${ARCHES[@]}"; do
    LABEL="$(label_for "$ARCH")"
    NAME="ZTrackerMac-${VERSION}-${LABEL}.dmg"
    DMG="dist/.staging/$NAME"
    APPCAST_STAGED="dist/.staging/appcast-${ARCH}.xml"
    STAGE="$(mktemp -d)/dmg"

    # Drop this arch's previous outputs first: a failure below must not leave a stale appcast
    # (or an older DMG) in dist/ to be uploaded beside the new one.
    rm -f "dist/$NAME" "dist/appcast-${ARCH}.xml"

    echo "==> building the app ($ARCH / $LABEL)"
    LAST_BUILT_ARCH="$ARCH"
    scripts/build-app.sh release "$ARCH"

    echo "==> staging the disk image"
    mkdir -p "$STAGE"
    cp -R "$APP" "$STAGE/"
    ln -s /Applications "$STAGE/Applications"      # drag-to-install target

    echo "==> creating $NAME"
    rm -f "$DMG"
    hdiutil create -volname "Z-Tracker $VERSION ($LABEL)" -srcfolder "$STAGE" \
        -ov -format UDZO "$DMG" >/dev/null
    rm -rf "$(dirname "$STAGE")"

    if [[ -z "$ALLOW_UNSIGNED" ]]; then
        echo "==> signing the disk image"
        codesign --force --sign "$ZTRACKER_SIGN_ID" --timestamp "$DMG"

        echo "==> notarizing"
        RESULT="$(xcrun notarytool submit "$DMG" "${NOTARY_ARGS[@]}" --wait --output-format json)" \
            || die "notarytool submit failed for $NAME"
        STATUS="$(printf '%s' "$RESULT" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("status",""))' 2>/dev/null || true)"
        SUBMISSION="$(printf '%s' "$RESULT" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("id",""))' 2>/dev/null || true)"
        if [[ "$STATUS" != "Accepted" ]]; then
            echo "==> notarization status: ${STATUS:-unknown} — Apple's log:" >&2
            [[ -n "$SUBMISSION" ]] && xcrun notarytool log "$SUBMISSION" "${NOTARY_ARGS[@]}" >&2 || true
            die "notarization was not accepted for $NAME"
        fi
        echo "    status: Accepted"

        echo "==> stapling + validating"
        xcrun stapler staple "$DMG" >/dev/null
        xcrun stapler validate "$DMG" >/dev/null || die "stapled ticket didn't validate for $NAME"
        spctl -a -t open --context context:primary-signature "$DMG" 2>/dev/null \
            || die "Gatekeeper rejects $NAME"

        # Sparkle appcast (T-211): EdDSA-sign the finished .dmg and emit a one-item per-arch
        # feed. The enclosure points at this version's GitHub release asset; the running app
        # fetches the appcast from `releases/latest/download/appcast-<arch>.xml` (build-app.sh
        # SUFEEDURL). `sign_update` uses the private key in this machine's Keychain.
        echo "==> EdDSA-signing the .dmg + writing the appcast"
        SIG_ATTRS="$("$SIGN_UPDATE" "$DMG")"    # → sparkle:edSignature="…" length="…"
        [[ "$SIG_ATTRS" == *edSignature* ]] || die "sign_update produced no signature for $NAME"
        ENCLOSURE_URL="$REPO_URL/releases/download/v${VERSION}/$NAME"
        PUB_DATE="$(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S +0000')"
        NOTES="$(release_notes_html)"
        DESCRIPTION=""
        [[ -n "$NOTES" ]] && DESCRIPTION="      <description><![CDATA[$NOTES]]></description>"
        cat > "$APPCAST_STAGED" <<APPCASTXML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>Z-Tracker ($LABEL)</title>
    <item>
      <title>Version $VERSION</title>
      <pubDate>$PUB_DATE</pubDate>
      <sparkle:version>$VERSION</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>$MIN_OS</sparkle:minimumSystemVersion>
      <sparkle:fullReleaseNotesLink>$REPO_URL/blob/main/CHANGELOG.md</sparkle:fullReleaseNotesLink>
$DESCRIPTION
      <enclosure url="$ENCLOSURE_URL" $SIG_ATTRS type="application/octet-stream" />
    </item>
  </channel>
</rss>
APPCASTXML
        mv "$APPCAST_STAGED" "dist/appcast-${ARCH}.xml"
        echo "==> wrote dist/appcast-${ARCH}.xml"
    fi

    mv "$DMG" "dist/$NAME"
    echo "==> done: dist/$NAME"
done
# (the EXIT trap restores the host-arch app and cleans dist/.staging)
