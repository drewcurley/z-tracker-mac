# Review: fix/appresources-deep-bundle-layout — final (T-233)

**Status:** PASS — restores full `swift test` (green again) after the 2026 Xcode update moved the
SwiftPM resource bundle to a deep layout, and future-proofs the app's runtime sprite loader against
the same shift. No app-behavior change; no release cut here.

unanimous-consensus: T-233

## What changed
- `AppResources.searchRoots` now probes both `…/<bundle>` (flat) and `…/<bundle>/Contents/Resources`
  (deep) for each nested candidate, so resource lookup works on old and new toolchain layouts.

## Root cause
The toolchain update changed the nested resource bundle from flat to a deep macOS bundle; the
direct-path loader only composed the flat path, so every image lookup returned nil. Verified it was
a lookup failure, not a decode failure (both CGImage paths decode the real PNGs fine standalone).

## Sign-offs
- [x] Analyst — scope is exactly "make the resolver find resources under the new layout"; no feature
      creep. Severity note recorded: this also guards shipped releases, not just CI/tests.
- [x] Architect — preserves the deliberate T-203 design (no `Bundle.module`/`Bundle(url:)`; plain
      `FileManager.fileExists` on composed paths). No new trust surface.
- [x] Backend/DevOps — minimal, localized change to the search-root composition; both layouts probed,
      deduped; correct for the app (currently flat) and the test bundle (now deep).
- [x] SDET — the pre-existing `AppResourcesTests.resolvesKnownResources` is the regression guard (was
      failing, now passes); its doc comment records the deep-layout cause. **Full suite 791/791 green**
      (217 ZTrackerMac + 574 TrackerCore), up from ~381 issues.
- [x] Ops — restores the "passing tests" gate that T-232 and future ships depend on; the same fix
      prevents a toolchain-driven deep `.app` bundle from silently breaking sprites in a release.
- [x] Review Coordinator — T-233 filed; INDEX updated; no CHANGELOG entry (no user-facing change —
      internal build/test infra), consistent with prior tooling-only work (T-231); VERSION untouched.

## Items to address (follow-ups)
- None. (If a future toolchain changes the bundle folder name itself, `bundleFolder` would need
  updating — unrelated to this layout fix.)
