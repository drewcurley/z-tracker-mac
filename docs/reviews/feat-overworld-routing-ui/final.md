# Review: feat/overworld-routing-ui — final

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats.

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- [ ] True GYR (red/yellow accessibility distinctions) is not implemented —
      by design, blocked on the item/dungeon state layer, tracked as
      `T-012`. The current highlight is a real, correct "reachable/unmarked"
      computation, not a stand-in for red/yellow — but flagging so it isn't
      mistaken for the reference app's full feature.
- [ ] `ladder`/`raft`/`isMirror` are hardcoded placeholders in
      `OverworldMapView` (documented in code and `docs/domain.md` § 6) —
      routes computed assuming full item possession and a non-mirrored
      overworld until `T-012` wires real state.
- [ ] The destination-picker menu isn't built; the map only supports the
      passive "hover shows nearby routes" mode, not "route to a specific
      chosen destination." Tracked as `T-012`.
- [ ] Pre-existing, unrelated to this task: at small window sizes the
      overworld map can render wider than the window (observed during
      manual verification at 700×550) — not a regression introduced here
      (the map's own sizing behavior predates T-011), not fixed in this PR.

## Suggestions (consider for polish)
- None beyond the above.

## Agent Sign-offs
- [x] Analyst — scope explicitly re-negotiated mid-task after
      `OverworldRouteDrawing.fs` surfaced a hidden dependency (the item/
      dungeon state layer) on full GYR; rather than silently shipping a
      "fake GYR" or blocking indefinitely, the scope was cut cleanly to what
      current state actually supports, with the real gap seeded as `T-012`
      rather than left implicit.
- [x] Architect — no security-relevant surface; pure data/algorithm code
      plus a read-only UI overlay.
- [x] Data Engineer — N/A structurally (no schema changes); the
      `routeHighlight` computation's correctness was verified the same way
      prior routing tasks were — hand-derived expected outputs checked
      against the actual ported graph before writing assertions.
- [x] Backend — N/A (no server).
- [x] Frontend — **this is the sign-off that matters most for this task**:
      the responsive-coordinate rendering (`GeometryReader`-relative
      fractional offsets, not the reference's fixed-pixel `Canvas`) is new
      ground for this app, and was verified by actually resizing the
      running app's window and re-screenshotting, not just by code
      inspection.
- [x] UX — the "reachable, unmarked" highlight is visually distinct
      (bold/pale green) and doesn't claim to be full GYR; no misleading
      color semantics introduced.
- [x] Test Engineer — 5 new tests in `OverworldRouteHighlightTests.swift`,
      each with hand-derived expected costs/lines checked against the
      static+dynamic graph before running (not fit-to-output), covering
      bold/pale selection, tie-at-cutoff extension, zero-budget, empty-set,
      and unresolvable-destination edge cases. 73/73 total passing.
- [x] DevOps — no CI/deploy changes.
- [x] Review Coordinator — process followed; scope change documented in
      `tasks/T-011.md`'s own activity log and description, not silently
      absorbed; `docs/domain.md` § 4.4/§ 6 updated to state exactly what
      shipped vs. what's deferred; `T-012` seeded with the real remaining
      scope (including a note that it likely needs its own foundation-first
      breakdown, mirroring `T-009`/`T-010`'s shape).

## Lens Sign-offs (major decision: shipping a deliberately reduced scope
instead of the originally-planned full GYR)
- [x] CEO/Purchasing/Investor/Marketing — N/A (internal solo project).
- [x] PM — the AskUserQuestion decision point (minimal slice vs. pivot to
      state layer vs. build inline) was a genuine judgment call put to the
      developer rather than assumed; developer chose the option that ships
      real, working value now without pretending the deferred parts are
      done.
- [x] Adopter (developer using their own app) — hovering the map now shows
      real, useful route information immediately, which is a meaningfully
      better tracker experience than before this task, even without full
      GYR.
- [x] Builder — the fractional-offset geometry technique (converting the
      reference's fixed-pixel `coords` function to tile-relative fractions)
      is a reusable pattern for any future overlay that needs to draw
      across this app's reflowing grid.

## Regression safety
- Full suite: 68/68 → 73/73, no regressions.
- `swift build` clean.
- Manual verification against the running app (see `tasks/T-011.md`
  "Manual verification"), including two window-resize checks.

## Out of scope (tracked as `T-012`)
- True GYR (red/yellow), the destination-picker menu, live item-possession/
  mirror-overworld state wiring — all require the item/dungeon state layer,
  which does not exist in `z-tracker-mac` yet.
- The take-any pie-menu accelerator and hover magnifier.
