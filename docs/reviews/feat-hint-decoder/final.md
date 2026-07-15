# Review: feat/hint-decoder — final (T-039.1)

**Status:** PASS — Hint Decoder: phrase→meaning translation + region picker + dungeon→hint sync.

unanimous-consensus: T-039.1

## Context
T-039 shipped the per-target `HintLabel` region pickers but not the *decoder*:
the player still had to know that "Aquamentus Awaits" means Level 1. This task
ports `MakeHintDecoderUI` — the phrase→meaning translation table — which is the
actual point of the feature. Scope was corrected mid-build after user feedback
(the first draft was a bare region-tagger with no phrase translation).

## Sign-offs
- [x] Analyst — scope: translate the in-game hint phrases and record the hinted
      region, in one popover. Matches the reference `MakeHintDecoderUI`. The
      dungeon→hint auto-sync is a user-requested addition ("when we place a
      marker for a dungeon… update its hint location to reflect actual region").
      Map auto-darkening explicitly de-scoped by the user (informational only).
- [x] Data — `HintPhrases.levelHints` strings are verbatim from
      `OverworldData.hintMeanings` (OverworldData.fs:10-22); `otherHints` from
      `UIComponents.fs:762-790`. `forZoneChar` is the exact inverse of
      `zoneChar` (round-trip tested over all cases). No schema change — the
      picker writes the existing `levelHints`.
- [x] Frontend — `HintDecoderView` is a `Grid` of phrase (serif italic orange) →
      meaning → `HintLabel`; "Other hints" is a `DisclosureGroup`. Width grows
      340→560 when expanded so meanings wrap without truncation. Reuses the
      T-039 picker, so no new hint-writing path.
- [x] UX — the phrase column mirrors the in-game wording for pattern-matching;
      meaning is plain, picker is the familiar two-char label. Sword rows read
      "White Sword item" / "Magical Sword" (the item, per the user). Other-hints
      note tells the player their spots may still hold useful items.
- [x] Backend — `onPlaceDungeon(number, col, row)` fires from `applyMark` only
      for `.dungeon(1…9)`; the parent maps the screen's `OverworldZones.zone`
      through `forZoneChar` into `levelHints`. Pure model write; no timer/route
      coupling.
- [x] Test Engineer — `HintPhrasesTests` (11 targets in order, boss→level,
      sword→item wording, other-hints coverage) + `HintZoneTests.forZoneChar`
      (round-trip, unknown/nil, known letters). 331/331. On-device: full
      decoder + other-hints render (no clipping past window edge); placing
      Dungeon 3 auto-set its hint to GR in both the decoder and the dungeon card.
- [x] Architect / DevOps — N/A (client-only, no infra/security surface).
- [x] Review Coordinator — task filed (T-039.1); INDEX updated.

## Regression safety
- Additive: new file `HintPhrases.swift`, rewritten `HintDecoderView`, one new
  optional closure `onPlaceDungeon` on `OverworldMapView` (defaulted no-op, so
  existing call sites are unaffected). The dungeon→hint write only runs when a
  dungeon mark is placed. Full suite 331/331, build clean debug + release.

## Notes
- Auto-darkening for "No feat of strength" / "Sail not" is intentionally omitted
  (user: informational only; those spots can still hold non-critical items).
  Recorded in T-039.1 "Out of scope", not silently dropped.
- The reference's halo-hover (show possible locations on the triforce icon) is
  not ported here — the region picker already records the hint; the hover is a
  separate presentation feature.
