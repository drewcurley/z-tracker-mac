# Releasing Z-Tracker (macOS)

How to cut a release, how the in-app update notice works, and the path to a
frictionless (notarized, auto-updating) build when you're ready.

## Cutting a release

1. **Bump the version.** Edit `VERSION` (e.g. `0.8.0` → `0.9.0`). This flows to
   `CFBundleShortVersionString` via `scripts/build-app.sh` and is what the update
   check compares against.
2. **Add a `CHANGELOG.md` entry** for the new version (newest first), with the same user-facing
   notes you'll put on the GitHub Release and in the release's `--notes`. Keep the three sources in
   sync — `CHANGELOG.md` is the cumulative history readers scan; the release notes are per-version.
3. **Commit** the bump + changelog on a branch and merge it (governance flow as usual).
4. **Build the disk images (both architectures):**
   ```bash
   scripts/make-dmg.sh
   ```
   Builds a **dedicated native binary per arch** (no universal/fat binary) and produces
   two git-ignored images:
   - `dist/ZTrackerMac-<version>-AppleSilicon.dmg` (arm64)
   - `dist/ZTrackerMac-<version>-Intel.dmg` (x86_64)

   Pass an arch to build just one (`scripts/make-dmg.sh arm64` / `x86_64`). The Intel
   slice cross-builds fine from an Apple-Silicon Mac, but can only be *runtime-tested* on
   actual Intel hardware (Rosetta runs the other direction).
   `make-dmg.sh` also **EdDSA-signs each `.dmg` and writes the Sparkle appcast** for that
   arch (`dist/appcast-arm64.xml`, `dist/appcast-x86_64.xml`) using the private key in your
   login Keychain (see Sparkle section). These MUST be attached to the release so installed
   apps can find the update.
5. **Tag and publish a GitHub Release** whose tag is the version, attaching **both** DMGs
   **and both appcasts**. The tag may be `v1.0.0` or `1.0.0` — the update check tolerates a
   leading `v`.
   ```bash
   gh release create v1.0.0 \
     dist/ZTrackerMac-1.0.0-AppleSilicon.dmg dist/ZTrackerMac-1.0.0-Intel.dmg \
     dist/appcast-arm64.xml dist/appcast-x86_64.xml \
     --title "Z-Tracker 1.0.0" --notes "…"
   ```
   The appcast enclosure points at this release's versioned DMG URL, and installed apps
   fetch `releases/latest/download/appcast-<arch>.xml` (a stable redirect to the newest
   release) — so **every** release must carry its appcasts.

That's it. Installed apps (v1.0.0+) auto-update in place via Sparkle; older copies show the
GitHub banner (below).

## The in-app update notice (T-174)

On launch the startup screen does one unauthenticated GET to
`https://api.github.com/repos/drewcurley/z-tracker-mac/releases/latest`, compares the
release tag to the running version, and — only if the release is strictly newer —
shows a dismissible banner with a **Download** link to the release page. It sends no
data, fails silently when offline, and is gated on the **"Check for updates on
launch"** setting (Settings → Other, default on).

When Sparkle is present (v1.0.0+), the banner's **Update now** button runs Sparkle's
in-place update instead of just linking out; the GitHub link stays as a fallback. On an
older copy without Sparkle it still just links to the `.dmg`.

## Installing an unsigned build (what to tell users)

Until the app is notarized (see below), macOS Gatekeeper blocks it on first open
because it isn't from an identified developer. Users do this **once** per version:

- **macOS 14 (Sonoma) and earlier:** right-click (or Control-click) the app →
  **Open** → **Open** in the dialog.
- **macOS 15 (Sequoia) and later:** double-click (it will be blocked), then
  **System Settings → Privacy & Security**, scroll to the "ZTrackerMac was blocked"
  message, and click **Open Anyway**.

Dragging the app from the `.dmg` to **Applications** first is recommended.

## Path to a frictionless build (notarization + Sparkle)

Nothing here needs a rewrite — the plumbing is already in place.

### Notarization (removes the Gatekeeper bypass entirely)

Requires an Apple Developer Program membership ($99/yr) and a *Developer ID
Application* certificate.

1. Store a notary credential once:
   ```bash
   xcrun notarytool store-credentials ztracker-notary \
     --apple-id you@example.com --team-id TEAMID --password <app-specific-password>
   ```
2. Build + notarize + staple in one step:
   ```bash
   ZTRACKER_SIGN_ID="Developer ID Application: Your Name (TEAMID)" \
   ZTRACKER_NOTARY_PROFILE="ztracker-notary" \
     scripts/make-dmg.sh
   ```
   `build-app.sh` detects the Developer ID identity and automatically signs with the
   hardened runtime + `Bundle/ZTrackerMac.entitlements` (required for notarization,
   and for microphone/voice under the hardened runtime). `make-dmg.sh` then submits
   the `.dmg` to the notary service and staples the ticket, so it opens with no
   warnings even offline.

## Sparkle in-place auto-update (T-211) — IMPLEMENTED

[Sparkle 2](https://sparkle-project.org) does download → verify → replace-in-place →
relaunch. It works on the **free/self-signed path today** (updates are authenticated by an
EdDSA signature, independent of Apple notarization); notarization, when it lands, only
removes the one-time Gatekeeper prompt on the *first* manual install and is a drop-in (above).

**How it's wired**
- `Sparkle` is a SwiftPM dependency; `SparkleUpdaterController` wraps `SPUStandardUpdaterController`.
- The app menu has **Check for Updates…**, and the startup banner's **Update now** triggers it.
- `Bundle/Info.plist.template` carries `SUPublicEDKey` (the public half of the signing key) and
  `SUFeedURL` = `@@SUFEEDURL@@`, which `build-app.sh` fills per-arch with
  `…/releases/latest/download/appcast-<arch>.xml`. Automatic checks are off — the app drives them.
- `build-app.sh` embeds + signs `Sparkle.framework` (Contents/Frameworks) and adds the rpath.
- `make-dmg.sh` EdDSA-signs each `.dmg` and writes `dist/appcast-<arch>.xml`. **Attach both
  appcasts to every release** (see "Cutting a release").

**Per-architecture feeds** keep the dedicated arm64 / Intel builds: each build points at its own
appcast, so it only ever updates to its own native binary.

**The signing key**
- The **private** EdDSA key lives in this machine's **login Keychain** (created once via Sparkle's
  `generate_keys`). It never enters the repo. Releases must be cut on a machine that has it, so
  `make-dmg.sh`'s `sign_update` can sign the `.dmg`.
- The **public** key is committed in `Info.plist.template` (`SUPublicEDKey`). If the private key is
  ever lost, generate a new pair and update the public key — but then only builds carrying the new
  public key can verify future updates. Back it up:
  `generate_keys -x sparkle_private_key.pem` (store the file somewhere safe, offline).

**First release note:** users on a pre-Sparkle build (≤ v0.9.2) can't auto-update *to* the first
Sparkle release — they take the GitHub banner and install it manually once. From then on it's
one-click.
