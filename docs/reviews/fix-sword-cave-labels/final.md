# Review: fix/sword-cave-labels — final (T-032)

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — bug-fix scope
(Backend + SDET + Ops emphasized); correction of a domain-labeling mistake in
T-025.4 per the user's clarification.

## Blockers
- none

## Warnings
- none.

## Agent Sign-offs
- [x] Analyst — scope: remove an incorrect label annotation only; no behavior
      added/removed beyond the label text.
- [x] Architect — no security surface; removes a now-dead view param.
- [x] Data Engineer — corrects the domain model of the label: the "White Sword
      Item" cave is a *location* holding a random item; the bomb upgrade
      replaces the white-sword *weapon* (`ITEMS.whiteSword`), a shuffled box
      item — not the cave. The weapon swap (T-025.4) already targets the right
      thing and is untouched.
- [x] Backend — N/A.
- [x] Frontend — `swordCaveLabel` loses the BU branch + param; `OverworldMapView`
      loses the unused `isWSMSReplacedByBU` prop and its `MainTracker…`
      pass-through. Helper marked `nonisolated` (pure), clearing a MainActor
      note.
- [x] UX — sword-cave marks read as plain locations again; the swordless swap
      still shows correctly on the actual item boxes/picker, which is where the
      weapon lives.
- [x] Test Engineer — the label test now asserts plain names; the icon-swap
      tests (whiteSword→BU only, others/wood unchanged) are unchanged and still
      pass. 247/247.
- [x] DevOps — no CI/asset change. `swift build` (debug+release) + `swift test`
      clean, no warnings.
- [x] Review Coordinator — `tasks/T-032.md` filed; INDEX updated; the
      distinction recorded in memory `reference_white-sword-item-vs-weapon`.

## Regression safety
- Contracts touched = none. Pure label/param change; the white-sword item swap
  is byte-for-byte unchanged. Full suite 247/247, no regressions. Builds clean.

## Out of scope
- **T-031** Extra Candles; **T-025.5** remaining chrome.
