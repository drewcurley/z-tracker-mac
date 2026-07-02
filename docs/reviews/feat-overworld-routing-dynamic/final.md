# Review: feat/overworld-routing-dynamic — final

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats.

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- [ ] Not yet wired into any UI — by design (`tasks/T-010.md` scope). GYR
      tile coloring / route-line rendering in `OverworldMapView` is the next
      follow-up (seeded below), not attempted here.
- [ ] `dynamicGraph`'s `recorderWarpDestinations`/`anyRoads` parameters are
      currently hand-passed by callers (tests only) — wiring them from live
      `TrackerModel` state (marked any-roads, whistleable dungeons) is part
      of the UI follow-up, not this task.
- [ ] Several `canonicalVertex` special cases carry the reference source's
      own "TODO check" comments, transcribed as-is rather than resolved —
      correctly not second-guessed (would be inventing a fact), but flagging
      so a future task doesn't assume they're fully settled.

## Suggestions (consider for polish)
- None beyond the above.

## Agent Sign-offs
- [x] Analyst — scope matches `tasks/T-010.md` exactly: dynamic graph layer
      + pathfinding search only, UI wiring correctly deferred to a follow-up
      rather than folded in here.
- [x] Architect — no security-relevant surface; pure data/algorithm code.
- [x] Data Engineer — screen-scroll tables ported line-for-line from
      `staticMirrorScreenScrolls`/`staticNormalScreenScrolls` (18 + 16
      edges, counts matched against the source); `populateDynamic`'s
      `addExtra` cross-product logic for recorder-warp/any-road edges ported
      structurally, not paraphrased.
- [x] Backend — N/A (no server); the graph and search remain pure, testable
      value types/functions.
- [x] Frontend — N/A this task (no UI).
- [x] UX — N/A this task (no UI).
- [x] Test Engineer — **this is the sign-off that matters most for this
      task**: 9 new tests, anchored by a hand-verified known-route
      regression (`(1,6)→(0,6)` forced to cost 8 — traced by hand through
      the static edge list to confirm `(0,6)` has no other graph connection,
      not just asserting whatever the algorithm happened to return), plus
      direct/two-hop adjacency, ladder shortcut, recorder-warp, and
      any-road-warp cost assertions, each hand-derived from the source
      before running. 68/68 total passing.
- [x] DevOps — no CI/deploy changes.
- [x] Review Coordinator — process followed; `domain.md`'s routing open
      question updated to reflect the algorithm as fully ported, with the
      UI-wiring gap stated explicitly rather than implied; `tasks/T-010.md`
      acceptance criteria checked off with evidence, not just marked done.

## Lens Sign-offs (major decisions — none new; faithful port of an
already-scoped algorithm)
- [x] CEO/Purchasing/Investor/Marketing — N/A.
- [x] PM — correctly kept this as its own task rather than bundling in UI
      wiring, matching the split the developer approved when routing's true
      scope was first discovered (`tasks/T-009.md`).
- [x] Adopter — N/A yet (no UI surface for the developer to use).
- [x] Builder — the `Set`-backed priority-queue-entry technique (replicating
      F#'s `Set`-based automatic deduplication) is a subtle but important
      correctness detail that a naive array-backed queue would have missed
      silently; documented at the point of use for the next person reading
      this code.

## Regression safety
- Full suite run before and after: 59/59 → 68/68, no regressions.
- `swift build` clean.

## Out of scope (tracked as follow-ups)
- GYR tile coloring and route-line rendering in `OverworldMapView`.
- Wiring `dynamicGraph`'s live-state parameters (ladder/raft possession,
  marked any-roads, recorder warp destinations, mirror/screen-scroll
  settings) from `TrackerModel`/`TrackerOptions` instead of hand-passed
  test arguments.
- The take-any pie-menu accelerator and hover magnifier.
