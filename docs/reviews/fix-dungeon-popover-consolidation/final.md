# Review: fix/dungeon-popover-consolidation — final (T-145)

**Status:** PASS — the dungeon room-picker popovers go from 192 (3/cell) to 3
(grid-level), snappier + far smaller crash surface; residual NSPopover animation
left in place per the user's call.

unanimous-consensus: T-145

## Sign-offs
- [x] Analyst — fixes the reported ~500ms right-click delay and shrinks the
      crash-prone NSPopover count; the "instant custom overlay" is a deliberate,
      user-deferred follow-up (not in scope).
- [x] Architect — root cause (per-cell popover proliferation) removed by lifting
      state to the grid; anchoring uses the grid's deterministic static geometry.
- [x] Data — n/a; picker apply paths (DungeonRoomMark) unchanged.
- [x] Backend — one `activePicker` request + three presentation bindings; picker
      content reads the live `map.room(col:row:)`; 2nd-monster stay-open preserved.
- [x] Frontend / UX — anchors at the clicked room (live-QA confirmed), arrow edge
      `.bottom`, VoiceOver named actions routed through `onPick`, no-animation
      transaction on present.
- [x] SDET — behaviour-preserving refactor; **588 tests pass**; popover
      presentation/anchoring is inherently manual-QA (done live with the user).
- [x] DevOps — no infra change; `swift build` clean; app rebuilt & relaunched.
- [x] Review Coordinator — task filed (T-145); INDEX updated.

## Items to address (follow-up)
- Custom instant overlay to remove the NSPopover animation + crash entirely
  (deferred by user).
