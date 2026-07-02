# Deployment — z-tracker-mac

**Status:** forward-looking — no release has shipped yet. Describes the intended
distribution path for a native macOS desktop app; revise once the first release
is actually cut.

## What "deployment" means for this app

There is no server/cloud deployment — this is a local, offline desktop app. This
doc's equivalent of "environments" is: local dev build vs. a signed/notarized
release build distributed to end users (initially: just the developer).

## Environments

| Environment | What it is | How it's produced |
|---|---|---|
| Dev | Debug build run from Xcode / `swift build` | `xcodebuild` debug config, unsigned, ad-hoc run on the developer's own Mac |
| Release | Signed + notarized `.app`, distributed via GitHub Releases | `xcodebuild` release config + `codesign` + `notarytool` (Apple Developer ID) — **UNKNOWN — needs human confirmation**: whether an Apple Developer Program enrollment exists yet; without it, releases can only be run locally/unsigned (Gatekeeper will block distribution to other machines) |

## CI/CD

- **CI:** GitHub Actions, `.github/workflows/checks.yml`, runs `swift build` +
  `swift test` on `macos-14` runners for every PR and push to `main` (currently
  `continue-on-error: true` until the project scaffold exists — `tasks/T-002.md`
  must remove that before it provides real signal).
- **CD:** not yet built. Planned: a tag-triggered release workflow that builds,
  signs, notarizes, and attaches the `.app`/`.dmg` to a GitHub Release. Not
  started — tracked as a future task once there's a first feature-complete build
  worth shipping.

## Promotion path

None yet (no staged rollout makes sense for a single-binary desktop app with one
user). Once distributed beyond the developer, consider: pre-release tag →
manual smoke test → full release tag.

## Rollback

Users roll back by re-downloading a prior GitHub Release tag. No auto-update
mechanism is planned initially — **UNKNOWN — needs human confirmation** whether
Sparkle or a similar macOS auto-update framework will be added later.

## Update-this-doc-when

Update this file the moment: (a) the Xcode/SPM scaffold lands and `swift build`/
`swift test` produce real signal (remove `continue-on-error`), (b) code signing /
notarization is set up, (c) the first tagged release ships.
