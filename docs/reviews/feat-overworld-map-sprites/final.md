# Review: feat/overworld-map-sprites — final

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats.

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- [ ] Integer-scale snapping (ADR 0003's open implementation problem) not
      addressed — `.interpolation(.none)` keeps pixels crisp (no blur) but
      doesn't guarantee an exact-integer render scale at arbitrary window
      sizes. Worth a dedicated pass once more of the UI is sprite-rendered.
- [ ] Map background/terrain art still entirely unimplemented — flagged
      again so it isn't lost among the smaller follow-ups.

## Suggestions (consider for polish)
- None beyond the above.

## Agent Sign-offs
- [x] Analyst — scope matches T-007; resolving the count discrepancy along
      the way was in-scope (it directly blocked the index mapping this task
      needed), not scope creep.
- [x] Architect — asset reuse is legally clean (MIT, attribution recorded in
      `/NOTICE.md`, decision trail in ADR 0001); no new dependency, no
      network/security surface.
- [x] Data Engineer — `iconStripIndex` mapping is exhaustively tested
      against the reference app's own authoritative enum
      (`MapSquareChoiceDomainHelper`), not just spot-checked.
- [x] Backend — N/A (no server); atlas loading is a pure, testable function.
- [x] Frontend — **verified visually on the running app**, not just unit
      tests: marked tiles, confirmed the actual reference-app icon renders
      crisply in place of the placeholder.
- [x] UX — real pixel art now matches the "near pixel-perfect" goal for the
      one piece of UI it covers; nearest-neighbor scaling preserves the
      reference app's visual character.
- [x] Test Engineer — added a new `ZTrackerMacTests` target (the app target
      had zero tests before this — a real gap, now closed) with 4 new tests,
      plus 3 more in `TrackerCoreTests` for `iconStripIndex`; 44/44 total
      passing, including an exhaustive all-36-indices completeness check.
- [x] DevOps — no CI/deploy changes; `swift test` picks up the new target
      automatically, verified.
- [x] Review Coordinator — process followed; `domain.md`, `stack.md`
      updated with real resolutions; the `Canvas`-vs-`Image` deviation from
      ADR 0002's literal wording is documented, not silently substituted.

## Lens Sign-offs (major decisions — none new; implementation of an already-decided approach)
- [x] CEO/Purchasing/Investor/Marketing — N/A.
- [x] PM — closes out the last major open item from the overworld map's
      first slice cleanly.
- [x] Adopter — the app now visually resembles the tool the developer
      actually wants to build, for the first time — a meaningful milestone.
- [x] Builder — finding the authoritative `MapSquareChoiceDomainHelper`
      source (rather than continuing to guess from a screenshot) is exactly
      the habit this project needs for the much larger dungeon tracker.
