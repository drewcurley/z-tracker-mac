# Review: feat/periodic-reminders — final (T-089)

**Status:** PASS — the four time-based periodic reminders ported.

unanimous-consensus: T-089

## What changed
Ported `Z1R_WPF/Reminders.fs:193-243` — coast item (3-min), recorder spots,
power-bracelet spots, and boomstick book (5-min each) — into `ReminderEngine`,
gated by an **injected cooldown clock** (`now: Date`) so it stays deterministic in
tests. `pollReminders` supplies `Date()` plus the derived inputs (coast item value,
whistle/PB spot counts, book-shop-marked). New `ITEMS.spokenName` for the coast
item's name.

## Sign-offs
- [x] Analyst — completes the audit follow-up (all four unported reminders). The
      "magical sword before dungeon nine" DungeonFeedback line is noted as separate.
- [x] Architect — clock injected, not read inside the engine; no global time.
- [x] Data — spot counts from `mapState`; book shop from a grid scan; coast value
      from `ladderBox.cellCurrent`.
- [x] Backend — cooldown + prev-count gating matches the reference (recorder/PB
      only re-nag when the count hasn't shrunk; boomstick timer resets only on fire).
- [x] Frontend — reuses the toast + `SpeechEngine`; categories/toggles already
      existed (recorder/PB/boomstick default off, coast on — matching the reference).
- [x] UX — faithful text; "beau" phonetic dropped in favor of "bow" (correct on
      screen; the live voice reads it fine).
- [x] SDET — 449 tests (6 new: 5 engine incl. cooldown/shrink gating, 1 display).
      Coast reminder verified on-device (toast fired, stacked without overlap).
- [x] DevOps — no infra change.
- [x] Review Coordinator — T-089 marked completed; INDEX updated.

## Regression safety
- Periodic params default so the engine is unchanged when no relevant item is
  held. `now` defaults to `.distantPast` in the engine signature; the app passes
  real time. Full suite green.
