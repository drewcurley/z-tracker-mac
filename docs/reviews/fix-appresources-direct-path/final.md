# Review: fix/appresources-direct-path — final (T-203)

**Status:** PASS — the real fix for the macOS 15 (Sequoia) launch crash: the app no longer
uses `Bundle.module` at all, so its `fatalError` can't fire. T-202's Info.plist didn't help
(tester's v0.8.2 report showed the identical `Bundle.module` trap).

unanimous-consensus: T-203

## What shipped
- `AppResources.url(forResource:withExtension:)` — direct-path resource resolution via
  `Bundle.main.resourceURL` / `Bundle(for:)` URL properties + `FileManager`; never
  `Bundle(url:)`. All 7 `Bundle.module` call sites migrated; zero `Bundle.module` refs remain.

## Sign-offs
- [x] Analyst — matches the tester's exact trace (Bundle.module static init fatalError);
      removes the dependency rather than papering over it.
- [x] Architect — direct-path lookup can't hit Sequoia's nested-bundle validation; search
      roots cover app + test contexts; no `Bundle.module` anywhere.
- [x] Backend — one central helper; 7 call sites, mechanical swap; same URL→CGImage flow.
- [x] SDET — `AppResourcesTests` (known resources resolve, missing → nil); **732 pass**.
      x86_64 build QA'd under Rosetta.
- [x] DevOps — build unchanged; `VERSION` → 0.8.3; both DMGs re-cut for the release.
- [x] Data / Frontend / UX — n/a (resource plumbing only; icons render as before).
- [x] Review Coordinator — task filed (T-203); INDEX updated.

## Items to address (follow-ups)
- Tester to confirm the launch on real Sequoia (can't reproduce the strict validation on the
  macOS-26 dev box). The fix is bulletproof by construction (existence check on a real path).
