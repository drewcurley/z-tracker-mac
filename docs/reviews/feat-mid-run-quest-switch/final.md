# Review: mid-run quest switch — final (T-237)

**Status:** PASS — the overworld quest can be changed mid-run from the in-run Settings window, behind
a confirmation. User tested it live. Ships (with T-236) as **v1.2.12**.

unanimous-consensus: T-237

## What shipped
- `TrackerModel.changeQuest(_:)` — mid-run-safe quest swap (no floor-heart re-seed).
- `OverworldQuest.displayName` — shared quest label.
- `SettingsWindowView` quest picker + confirmation dialog; `ZTrackerMacApp` passes `model` in.

## Sign-offs
- [x] Analyst — matches the request (fix a wrongly-picked quest without restarting); confirmation
      kept as a guard per the user, even though first/mixed-first is non-destructive.
- [x] Architect — no new persistence (quest already saved); leverages the value-recompute
      architecture so all quest-derived state updates live; marks are independent and untouched.
- [x] Backend — `changeQuest` deliberately omits `selectQuest`'s one-time floor-heart seeding so
      dungeon state isn't disturbed mid-run.
- [x] Frontend/UX — picker lives only in the in-run Settings (startup has its own); confirmation
      states that markings are kept but may need review; reuses the shared display names.
- [x] SDET — `TrackerModelTests.changeQuestKeepsMarks` (quest swaps, overworld marks preserved).
      **799 tests pass.**
- [x] DevOps — clean build/test; ships notarized with v1.2.12.
- [x] Review Coordinator — T-237 filed; INDEX + CHANGELOG (1.2.12) updated; VERSION → 1.2.12.

## Items to address (follow-ups)
- For far-apart switches (e.g. first ↔ second) that change the valid-spot distribution, a future
  pass could flag specific now-invalid marks; today's confirmation is a general heads-up.
