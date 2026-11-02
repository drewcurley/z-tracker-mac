# Releasing Z-Tracker (macOS)

How to cut a release, how the in-app update notice works, and the path to a
frictionless (notarized, auto-updating) build when you're ready.

## Cutting a release

1. **Bump the version.** Edit `VERSION` (e.g. `1.2.12` → `1.2.13`). This flows to
   `CFBundleShortVersionString` via `scripts/build-app.sh` and is what the update check compares.
2. **Finalize the `CHANGELOG.md` entry** — rename `## [Unreleased]` to `## [<version>] — <date>`.
   `make-dmg.sh` embeds this section in the appcast, so it's what Sparkle shows users in the update
   dialog; the appcast also links the full CHANGELOG, so users who skip versions still see history.
3. **Commit** the bump + changelog on a branch and merge it (governance flow as usual). The release
   must be built from a **clean, merged `main`** — `make-dmg.sh` refuses a dirty tree.
4. **Build, sign, notarize and verify both architectures:**
   ```bash
   ZTRACKER_SIGN_ID="Developer ID Application: ANDREW MICHAEL CURLEY (VB8Y4UKJPQ)" \
   ZTRACKER_NOTARY_PROFILE="ztracker-notary" scripts/make-dmg.sh
   ```
   **Preflight first (T-242):** before building anything it checks the signing identity is in the
   keychain, the notarization credentials actually work (`notarytool history`), Sparkle's
   `sign_update` is present, and the tree is clean — so a missing credential fails in a second, not
   ten minutes in.

   Notarization credentials — either:
   - a **keychain profile** (`ZTRACKER_NOTARY_PROFILE`), created once with
     `xcrun notarytool store-credentials ztracker-notary --apple-id … --team-id VB8Y4UKJPQ` (it
     prompts for the app-specific password). This profile **has vanished from the keychain once**
     mid-release; if preflight reports it broken, re-run `store-credentials`; or
   - an **App Store Connect API key** — a `.p8` file on disk, which can't disappear from the
     keychain: `ZTRACKER_NOTARY_KEY=/path/AuthKey_XXXX.p8 ZTRACKER_NOTARY_KEY_ID=XXXX
     ZTRACKER_NOTARY_ISSUER=<uuid>` (create the key in App Store Connect → Users and Access →
     Integrations; keep the `.p8` outside the repo).

   For each arch it builds a dedicated native binary (asserting the binary's arch), signs it with
   the hardened runtime and verifies the signature, makes the DMG, **code-signs the DMG**,
   notarizes it (checking the result is `Accepted`, printing Apple's log otherwise), staples,
   validates the ticket, checks Gatekeeper accepts it, EdDSA-signs it and writes
   `dist/appcast-<arch>.xml`. Outputs:
   - `dist/ZTrackerMac-<version>-AppleSilicon.dmg` + `dist/appcast-arm64.xml`
   - `dist/ZTrackerMac-<version>-Intel.dmg` + `dist/appcast-x86_64.xml`

   **If it fails partway**, nothing half-finished is left under a release name: each arch is
   staged in `dist/.staging` and only moved into `dist/` once verified, and that arch's old DMG and
   appcast are removed first. Fix the cause and re-run **just the failed arch**
   (`… scripts/make-dmg.sh x86_64`). Either way, the project-root `./ZTrackerMac.app` is rebuilt
   for the host arch on exit, so it never stays an Intel/Rosetta build (T-231).

   `ZTRACKER_ALLOW_UNSIGNED=1` packages a local test DMG without signing/notarizing (no appcast is
   written); `ZTRACKER_ALLOW_DIRTY=1` skips the clean-tree check. Never publish either.
5. **Publish the GitHub Release**, tagged at the exact commit you built (so the tag can't drift to
   whatever `main` is when you publish), attaching **both** DMGs **and both appcasts**:
   ```bash
   gh release create v<version> --target "$(git rev-parse HEAD)" \
     dist/ZTrackerMac-<version>-AppleSilicon.dmg dist/ZTrackerMac-<version>-Intel.dmg \
     dist/appcast-arm64.xml dist/appcast-x86_64.xml \
     --title "v<version> — …" --notes "…"
   ```
   Installed apps fetch `releases/latest/download/appcast-<arch>.xml` (a stable redirect to the
   newest release), so **every** release must carry both appcasts.
6. **Verify:** `curl -sL …/releases/latest/download/appcast-arm64.xml` (and `-x86_64`) resolves to
   the new version.

That's it. Installed apps (v1.0.0+) auto-update in place via Sparkle; older copies show the
GitHub banner (below).

> **Intel end-of-life (plan ahead):** macOS 26 is the last Intel macOS and Xcode is deprecating
> x86_64. When Intel builds stop, keep attaching a frozen `appcast-x86_64.xml` (pointing at the
> last Intel DMG) to every later release — otherwise `releases/latest/download/appcast-x86_64.xml`
> 404s and Intel users silently stop getting update notices.

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
  public key can verify future updates. **Back it up** — losing it means installed users can never
  auto-update again: run `generate_keys -x ~/sparkle_private_key.pem` from **outside the repo**
  (the repo `.gitignore` also blocks `sparkle_private_key*`, T-243), move the file to encrypted
  offline storage, and delete the plaintext copy.

**First release note:** users on a pre-Sparkle build (≤ v0.9.2) can't auto-update *to* the first
Sparkle release — they take the GitHub banner and install it manually once. From then on it's
one-click.
