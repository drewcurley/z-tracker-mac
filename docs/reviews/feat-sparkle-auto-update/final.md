# Review: feat/sparkle-auto-update — final (T-211)

**Status:** PASS — Sparkle in-place auto-update on the free/self-signed path, verified end-to-end
locally (a 0.9.2 app updated itself to 1.0.1 over a localhost appcast, EdDSA-verified, ~6s).
Ships as **v1.0.0**.

unanimous-consensus: T-211

## What shipped
- Sparkle 2 SwiftPM dep + `SparkleUpdaterController` (wraps `SPUStandardUpdaterController`).
- Menu **Check for Updates…**; startup banner **Update now** (in-place) with a GitHub fallback.
- `Info.plist`: `SUPublicEDKey` + per-arch `SUFeedURL` (`build-app.sh` injects
  `…/releases/latest/download/appcast-<arch>.xml`); automatic checks off.
- `build-app.sh` embeds + signs `Sparkle.framework` (+ rpath); `make-dmg.sh` EdDSA-signs each
  `.dmg` and emits `dist/appcast-<arch>.xml` (attach to every release).

## Verification
End-to-end local test (`scratchpad/e2e-*.sh`): fake newer version served over localhost, an
installed **0.9.2** app → **Check for Updates…** → downloaded, **EdDSA signature verified**,
replaced in place, relaunched as **1.0.1** (on-disk `CFBundleShortVersionString` flipped). Also
confirmed the embedded framework loads at runtime (rpath resolves; no dyld errors). **739 tests
pass.**

## Sign-offs
- [x] Analyst — matches the explicit request; first-release bootstrap + notarization-later noted.
- [x] Architect — **security:** updates authenticated by EdDSA (public key in bundle, private key
      in Keychain, never in repo), independent of notarization; per-arch feeds prevent cross-arch
      installs; nested framework/helpers signed before the app (no blanket `--deep` on the app);
      automatic checks off (no silent network on launch beyond the existing gated GitHub check).
- [x] Backend — updater is a thin wrapper; check driven only by explicit user action.
- [x] Frontend — framework embeds + loads; banner/menu gate on `canCheckForUpdates`; optional
      `updater` keeps previews safe.
- [x] UX — one-click update replaces the manual GitHub download; fallback link retained.
- [x] SDET — E2E install verified (version flip on disk); 739 unit tests pass.
- [x] DevOps — `build-app.sh`/`make-dmg.sh` produce a signed, framework-embedded app + signed
      DMGs + appcasts; `RELEASING.md` updated (attach appcasts every release; key handling/backup).
- [x] Review Coordinator — T-211 filed; INDEX updated; VERSION → 1.0.0.

## Items to address (follow-ups)
- Notarization once the paid Apple Developer account is active (drop-in; removes the one-time
  Gatekeeper prompt on first manual install). Tracked by the user with Apple support.
- Consider retiring the separate GitHub `UpdateChecker` once everyone is on a Sparkle build (kept
  now as the banner trigger + fallback).
