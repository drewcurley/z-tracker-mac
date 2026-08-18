# Releasing Z-Tracker (macOS)

How to cut a release, how the in-app update notice works, and the path to a
frictionless (notarized, auto-updating) build when you're ready.

## Cutting a release

1. **Bump the version.** Edit `VERSION` (e.g. `0.8.0` → `0.9.0`). This flows to
   `CFBundleShortVersionString` via `scripts/build-app.sh` and is what the update
   check compares against.
2. **Commit** the bump on a branch and merge it (governance flow as usual).
3. **Build the disk images (both architectures):**
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
4. **Tag and publish a GitHub Release** whose tag is the version, attaching **both** DMGs.
   The tag may be `v0.9.0` or `0.9.0` — the update check tolerates a leading `v`.
   ```bash
   gh release create v0.9.0 \
     dist/ZTrackerMac-0.9.0-AppleSilicon.dmg dist/ZTrackerMac-0.9.0-Intel.dmg \
     --title "Z-Tracker 0.9.0" --notes "…"
   ```

That's it. The next time anyone launches an older copy, they'll see the update
notice (below).

## The in-app update notice (T-174)

On launch the startup screen does one unauthenticated GET to
`https://api.github.com/repos/drewcurley/z-tracker-mac/releases/latest`, compares the
release tag to the running version, and — only if the release is strictly newer —
shows a dismissible banner with a **Download** link to the release page. It sends no
data, fails silently when offline, and is gated on the **"Check for updates on
launch"** setting (Settings → Other, default on).

It does **not** auto-install — it points people at the new `.dmg`. Auto-install is the
Sparkle step below.

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

### Sparkle (one-click auto-update)

Once builds are notarized, add [Sparkle 2](https://sparkle-project.org) for
download-install-relaunch updates:

- Add the Sparkle SwiftPM package and an `SPUStandardUpdaterController`.
- Generate an EdDSA key; publish an **appcast** XML feed (e.g. on GitHub Pages or in
  the repo) listing each release's `.dmg`, version, and signature.
- The check-on-launch notice (T-174) can then be retired or kept as a fallback.

This is a clean addition on top of the current setup — the version/`VERSION` plumbing
and the notarized `.dmg` output are exactly what Sparkle's appcast needs.
