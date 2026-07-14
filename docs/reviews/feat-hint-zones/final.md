# Review: feat/hint-zones — final (T-039)

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator, 9 hats.

## Blockers / Warnings
- [ ] Setting a hint doesn't yet highlight the hinted region on the map — a
      natural follow-on via `HintZone.zoneChar` ↔ the Zones overlay.
- [ ] The white/magical-sword box hint-highlight (`makeHintHighlight`) and hint
      hotkeys aren't ported.

## Agent Sign-offs
- [x] Analyst — scope: the hint labels + picker above dungeons + sword boxes.
      Map highlighting / hotkeys are follow-ons.
- [x] Architect — no security surface; a value enum + an array on the model + a
      picker view.
- [x] Data Engineer — `HintZone` (11) transcribed from the reference incl. the
      `zoneChar`↔`owMapZone` mapping; `levelHints` is 11 slots (dungeons 0–8,
      WS 9, MS 10). A test asserts the groundhog reset keeps hints.
- [x] Backend — N/A.
- [x] Frontend — `HintLabel` (popover-backed) above each `DungeonCardView` and
      beside the sword icons in the header, bound to `$model.levelHints[i]`;
      `HintZonePicker` renders the 11-zone grid + the target's current hint.
- [x] UX — matches the reference's two-char labels + zone picker; yellow when
      set, gray Unknown. Verified on-device (Dungeon 2 → DM).
- [x] Test Engineer — 270→274: 11 distinct zones + zoneChar↔owMapZone, target
      indices, model get/set, reset-keeps-hints.
- [x] DevOps — no CI/asset change. `swift build` (debug+release) + `swift test`
      clean.
- [x] Review Coordinator — task filed; INDEX updated.

## Regression safety
- Contracts touched = none. `TrackerModel` gains a defaulted `levelHints`;
  `DungeonTrackerView` became `@Bindable` for the element bindings. Full suite
  270→274. Builds clean (debug + release).
