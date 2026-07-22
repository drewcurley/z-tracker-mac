# Review: feat/custom-map-fog — final (T-167)
**Status:** PASS — custom-map import + fog-of-war, user-QA'd across two rounds.
unanimous-consensus: T-167

## Blockers
_none remaining_ — all four QA findings fixed in this branch (see Warnings-resolved).

## Warnings — resolved during review
1. **Dead spots leaked through non-view paths.** Only the view gated `alwaysEmpty`; click,
   hover, voice, and hotkeys each consulted `OverworldInstance` directly, so a third of the
   map stayed unclickable. Collapsed onto `TrackerModel.isDeadSpot(x:y:)` as the one source
   of truth.
2. **Mixed-Second unreachable.** The setup prompt was a `confirmationDialog`, which is
   alert-backed on macOS and silently drops buttons past ~3. Replaced with a `.sheet`.
3. **Fairy never drew.** The fairy render was nested under `if isAlwaysEmpty` — true by
   coincidence for vanilla fairy spots, never true on a custom map. Un-nested; it is map
   truth, not a mark.
4. **Imported maps rendered misaligned/zoomed.** Per-screen slicing truncated
   (`width / 16`) and then aspect-fill-cropped. Replaced with one stretched image over the
   grid; slicing code deleted rather than left dormant.

## Suggestions (not taken)
- Auto-detect the screen grid from image dimensions. Rejected: the user confirmed the map
  shape is always a consistent single image, so a stretch is exact and detection would add
  a failure mode for no gain.

## Sign-offs
- [x] **Analyst** — scope matches the request (import, hide-until-marked, quest prompt,
      vanilla machinery off, placeable fairies, gettable irrelevant). Quest semantics
      corrected against the user's own definition, not assumed.
- [x] **Architect** — no new I/O surface beyond a user-chosen file read via `NSOpenPanel`;
      image memoized per path; no network, no writes outside the existing save dir.
- [x] **Data Engineer** — `customMapRevealed` / `customFairySpots` / `customMapImagePath`
      added as **optional** in the `Codable` state, so pre-T-167 saves decode; covered by a
      key-stripping regression test. Restore validates array sizes as before.
- [x] **Backend Engineer** — reveal-on-mark lives in `setMark`/`toggleCustomFairy` so every
      caller (UI, voice, hotkeys) gets it for free.
- [x] **Frontend Engineer** — one stretched image + gradient fog; no per-tile bitmaps, so
      128 covers don't cost framerate. Mirror-overworld works unchanged (the shared image
      sits inside the mirrored container).
- [x] **UX Designer** — fairy fountain grouped with the other "what's on this screen" marks
      under Potion shop, not with the fog utilities; "gettable" hidden rather than shown
      wrong; setup sheet explains what the quest choice does and does not control.
- [x] **SDET** — 637 tests green. New coverage: reveal-on-mark, no-dead-spots sweep, spot
      count strictly larger on a custom map, fairy toggle + reveal-on-place, save round
      trip, pre-T-167 backward compat.
- [x] **DevOps** — no infra, no new deps, no bundle-resource changes.
- [x] **Review Coordinator** — T-167 filed; INDEX updated.
