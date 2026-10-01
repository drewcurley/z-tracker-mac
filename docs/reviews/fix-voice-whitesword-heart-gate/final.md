# Review: voice white-sword heart gate — final (T-236)

**Status:** PASS — the voice item-box path now honors the same acquisition gate as the GUI picker, so
"set white sword item" no longer claims possession below the heart minimum. Ships (with T-237) as
**v1.2.12**.

unanimous-consensus: T-236

## What changed
- `ItemBoxMark.apply` gains `acquired: PlayerHas = .yes` (default preserves hotkey/left-click).
- `ItemBoxVoiceApply.apply` takes `playerState` and gates the placed state via
  `box.defaultAcquired(playerState)` (coast → ladder, white-sword → 4-heart minimum, armos → ungated).
- `VoiceController` passes `model.playerComputedStateSummary`.

## Sign-offs
- [x] Analyst — fixes the reported bug; scope limited to the voice path (hotkey parity noted as a
      possible follow-up).
- [x] Backend — reuses the existing `ItemAcquisitionGate`/`defaultAcquired` logic so voice and GUI
      can't drift; default param keeps all other callers unchanged.
- [x] Data — n/a.
- [x] SDET — new tests: below/at the heart gate, the ladder gate, armos ungated; existing voice tests
      updated for the new signature. **799 tests pass.**
- [x] UX — voice now matches the GUI's first-click behavior (identify-but-untaken), the least
      surprising result.
- [x] DevOps — clean build/test; ships notarized with v1.2.12.
- [x] Review Coordinator — T-236 filed; INDEX + CHANGELOG (1.2.12) updated.

## Items to address (follow-ups)
- Optional: gate the item **hotkey** fresh-mark the same way (currently claims `.yes` by deliberate
  older decision).
