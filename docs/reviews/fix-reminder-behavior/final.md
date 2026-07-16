# Review: fix/reminder-behavior — final (T-095)

**Status:** PASS — recorder one-shot (no perpetual spots) + unmark→remark re-fires.

unanimous-consensus: T-095

## Sign-offs
- [x] Analyst — two user-reported bugs; scoped to reminder-engine behavior.
- [x] Backend — `itemNudge` re-arms on unmark; count watermarks clamp down on drop;
      `completedDungeon`/hearts latches reset when the trigger clears.
- [x] Data — spot-count reminders (and their wrong count) removed; recorder/PB now
      one-shots keyed off item possession.
- [x] SDET — 451 tests: recorder one-shot + re-fire-on-remark + triforce re-fire;
      old recorderSpots/powerBraceletSpots tests removed.
- [x] Ops — bug-fix scope; no infra change.
- [x] Architect / Frontend / UX — N/A (engine-internal).
- [x] Review Coordinator — task filed (T-095); INDEX updated.

## Notes
- The recorder/PB nudges use the `haveKeyLadder` category (default on), so the user
  gets them; the now-boomstick-only `recorderPBSpotsAndBoomstickBook` category is
  unchanged.
- The "count reads 1" bug in `owWhistleSpotsRemain` is now moot for reminders (the
  reminder is gone); the recorder-destination widget uses a different derivation.

## Regression safety
- The `prior*`-based reminders were already transition-based; this brings the latch
  and count reminders in line. Full suite green.
