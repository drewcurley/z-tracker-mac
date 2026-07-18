# Review: feat/voice-command-editor — final (T-139)

**Status:** PASS WITH ITEMS — user-editable voice vocabulary (catalog + config +
editor); dungeon-region vocab and the popover crash tracked as follow-ups.

unanimous-consensus: T-139

## Sign-offs
- [x] Analyst — mirrors the hotkey-editor pattern the user asked for; dungeon vocab deferred.
- [x] Architect — grammar is now data-driven; action id → meaning stays in code, only
      phrases are editable/persisted. `VoiceConfig` is `@Observable`, seeded from the catalog.
- [x] Data — phrases persisted as JSON in UserDefaults; keyed by catalog id (unknown ids ignored).
- [x] Backend — `match()` is longest-phrase-wins across all actions (specific beats general).
- [x] Frontend / UX — single-line rows grouped by category, filter, per-action + global reset.
- [x] SDET — catalog/config/grammar unit-tested incl. a user-added phrase: **562 tests pass**.
- [x] DevOps — no infra change.
- [x] Review Coordinator — task filed (T-139); INDEX updated.

## Items to address (T-140+)
- Dungeon-region action vocabulary (room types / monsters-shared / floor drops / doors /
  entrances) + region-aware execution. Shop second item. Remove `/tmp` diagnostics.
- Investigate the dungeon room-chooser `.popover` ViewBridge crash (macOS 27 beta).
