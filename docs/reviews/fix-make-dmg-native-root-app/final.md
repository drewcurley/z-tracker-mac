# Review: fix/make-dmg-native-root-app — final (T-231)

**Status:** PASS — `make-dmg.sh` no longer leaves an Intel (Rosetta) build in the project root on an
Apple-Silicon dev machine. Build-tooling only; no app-code change, no VERSION bump, no release.

unanimous-consensus: T-231

## What changed
- `scripts/make-dmg.sh`: after the per-arch packaging loop, if the last-packaged arch ≠ the host
  arch, rebuild `./ZTrackerMac.app` for the host arch so the leftover local dev app is always native.

## Root cause
`build-app.sh` assembles into a fixed `./ZTrackerMac.app`; the make-dmg loop runs `arm64` then
`x86_64`, so the Intel build was the one left in the project root — launching under Rosetta and
tripping the macOS "won't run on a future macOS" warning. Shipped DMGs were never affected.

## Sign-offs
- [x] Backend/DevOps — minimal, correct fix at the right layer (the packaging script, not the app);
      guarded so a single-arch or host-arch-last invocation skips the redundant rebuild.
- [x] SDET — verified: the appended block passes `bash -n`; after a dual-arch package on Apple
      Silicon the root binary is `arm64`; the two shipped DMGs remain arm64 / x86_64 respectively.
      The 789 app tests are unaffected (no app-code change).
- [x] Ops — no release cut; the change only touches the developer's local artifact. Documented that
      the concurrent Xcode-license gate (`sudo xcodebuild -license accept`) was an unrelated env snag.
- [x] Review Coordinator — T-231 filed; INDEX updated; no CHANGELOG entry (no user-facing/app change,
      no release), consistent with prior tooling-only work.

## Items to address (follow-ups)
- Optional (deferred): have `build-app.sh` accept an output path so per-arch builds stage into
  separate dirs and never touch the project root at all — larger refactor, not needed for this fix.
