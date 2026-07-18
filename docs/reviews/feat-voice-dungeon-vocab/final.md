# Review: feat/voice-dungeon-vocab — final (T-140)

**Status:** PASS WITH ITEMS — dungeon-region voice vocabulary (rooms / monsters /
floor drops / doors / entrances) with region-aware, edge-guarded execution;
overworld-monster reuse and the popover crash tracked as follow-ups.

unanimous-consensus: T-140

## Sign-offs
- [x] Analyst — delivers the dungeon vocab deferred from T-139, incl. the user's
      compound-door and entrance-direction requests; overworld untouched (scope held).
- [x] Architect — grammar stays data-driven; `dungeonActions` returns `[DungeonAction]`
      (id → meaning in code, phrases editable). Region-first parse keeps door commands
      from being swallowed by cursor moves. `options` threaded into `VoiceController`.
- [x] Data — door state mapping per the user's convention (open=yes, blocked=no,
      key=yellow, shutter=purple, none=unknown); edge doors guarded against the
      `precondition` in `hDoorIndex`/`vDoorIndex`.
- [x] Backend — compound door scan (state+direction pairs), then entrance, then a single
      room/monster/drop via longest-phrase-wins `match(.dungeon)`.
- [x] Frontend / UX — editor lists the five new categories with a `↕` direction hint
      alongside the existing `#` number hint; single-line rows preserved.
- [x] SDET — grammar unit-tested (rooms/monsters/drops, transport number, single +
      compound doors, entrance direction, region-first non-eating): **568 tests pass**.
- [x] DevOps — no infra change; `swift build` clean.
- [x] Review Coordinator — task filed (T-140); INDEX updated.

## Items to address (T-141+)
- Wire the shared `monsters` category for the `.overworld` region.
- Shop second-item overwrite; progression toggles ("take wood sword"); dungeon dedup in
  the model; item boxes (armos/white-sword/coast) voice. Remove `/tmp` diagnostics.
- Investigate the dungeon room-chooser `.popover` ViewBridge crash (macOS 27 beta).
