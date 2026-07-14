# Review: feat/item-sprite-atlas — final

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats.

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- [ ] No visual consumer yet — the atlases are data (CGImage crops) tested for
      size/mapping. Whether the sprites *look* right (esp. the black→
      transparent masking) is confirmed when the dungeon-tracker UI renders
      them (next task).

## Suggestions (consider for polish)
- If the black-masking ever clips a legitimately-black pixel inside a sprite,
  switch to an alpha-channel source; the reference uses the same
  black-is-background convention, so parity is expected.

## Agent Sign-offs
- [x] Analyst — scope is the sprite-atlas foundation only (assets + slicing +
      the `ITEMS`→icon mapping), explicitly deferring every UI consumer. This
      is step 1 of the main-tracker epic, sized after the reference-app
      exploration.
- [x] Architect — no security surface. Assets are MIT-licensed (NOTICE.md
      updated); loading matches the existing `Overworld*Atlas` `Bundle.module`
      + `CGImage` pattern, now factored into a shared `AtlasLoader`.
- [x] Data Engineer — the 32-icon `icons7x7` order and the 13-icon
      `zelda_items16x16` order are transcribed from `Graphics.fs:530-548` /
      `:575-590`; the `ITEMS`→icon mapping is cross-checked against
      `allItemBMPsWithHeartShuffle` (`:778-779`) — book, boomerang, bow,
      power-bracelet, ladder, magic-boomerang, key, raft, recorder,
      red-candle, red-ring, silver-arrow, wand, white-sword, heart-container.
- [x] Backend — N/A (no server).
- [x] Frontend — `Image(atlasIcon:)` produces a nearest-neighbor pixel-art
      image from a crop; the atlases are `enum` namespaces with typed `Icon`
      cases, ready for the tracker views.
- [x] UX — N/A yet (no rendered surface); the assets are the recognizable
      Zelda item sprites, which the aesthetic-license note keeps (only the
      layout/styling around them may improve).
- [x] Test Engineer — 9 tests: dimensions/count for both sheets, per-index
      crop size for all 32 + 13 icons, out-of-range nil, the full `ITEMS`→icon
      mapping vs. the reference order, and the named `staircase` glyph.
      207/207 total.
- [x] DevOps — no CI/deploy changes; `swift build` + `swift test` clean.
- [x] Review Coordinator — process followed; `domain.md` § 6 note added;
      `tasks/T-020.md` filed; INDEX regenerated.

## Lens Sign-offs (foundation for a user-facing epic)
- [x] Builder — factoring the loader (`AtlasLoader`) and typing the icon
      indices (`Icon` enums) keeps the upcoming tracker-view code readable and
      the reference order pinned by test.
- [x] Adopter — unblocks the actual item/dungeon tracker the app is for.
- Other lenses — N/A (internal asset foundation).

## Regression safety
- Contracts touched = none (new assets + a new app-target file). Reflected in
  docs = yes. Cross-repo consumers = none. Compatibility = additive.
- Full suite: 198/198 → 207/207, no regressions. `swift build` clean.

## Out of scope (tracked as follow-ons)
- The main-tracker UI pieces that consume these atlases (dungeon item-tracker,
  item grid, blockers UI, room-grid view, T-015.6/.7).
