# Review: fix/overworld-tile-icons-wrong-asset — final

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats. Bug-fix tier per the
playbook's "When to Run What" table (Backend + SDET + Ops minimum) — full
9-hat pass done anyway given the size of the correction (touches shipped,
previously-reviewed rendering code from `T-006`/`T-007`).

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- [ ] The "darkened once obtained" variant is not implemented — every icon
      renders its "available" state, since the underlying player-state
      (`sword2Box.IsDone()`, `armosBox.IsDone()`, etc.) doesn't exist yet
      (`T-013`/`T-014`). This is a real, documented gap, not silently
      dropped.
- [ ] Two-item shop display isn't modeled — `OverworldTileMark.shop(ShopKind)`
      only carries one item. Extending it is a separate follow-up.
- [ ] HDN mode's lettered dungeon variant isn't implemented (`T-016`);
      dungeons always render the numbered/yellow variant regardless of the
      `hideDungeonNumbers` toggle's value.

## Agent Sign-offs
- [x] Analyst — scope is exactly the icon source/mapping correction; the
      three items above are correctly identified as separate, deferred
      concerns, not silently rolled into this fix or silently dropped.
- [x] Architect — no security-relevant surface; asset swap + rendering
      logic only.
- [x] Data Engineer — **this is the sign-off that matters most for this
      task**: the corrected mapping was verified two ways — (1) reading
      `theInteriorBmpTable`'s construction line-by-line against
      `MapSquareChoiceDomainHelper`'s value constants, and (2) generating
      pixel-accurate contact sheets of the real `ow_icons5x9.png`/
      `icons3x7.png` strips and visually confirming each icon's identity
      (sword colors, shop items, secret symbols) independently of the code
      reading — two independent sources agreeing, not one read trusted at
      face value.
- [x] Backend — N/A (no server).
- [x] Frontend — `TileView` correctly composites the small interior icon at
      the exact position/size fraction ported from the reference's
      `initFull()`, using fractional (not fixed-pixel) offsets consistent
      with this app's responsive layout — verified by resizing was not
      re-tested here (no resize-sensitive change), but the fraction-based
      math is the same pattern already verified in `T-011`.
- [x] UX — the corrected icons are visually correct Zelda 1 iconography
      (sword colors, shop items, secret symbols) rather than the previous
      full-tile ZHelper-style icons — a meaningful visual-fidelity
      improvement, not just an internal refactor.
- [x] Test Engineer — full rewrite of the icon-atlas and tile-mark tests:
      `OverworldInteriorIconAtlasTests`/`OverworldShopIconAtlasTests`
      (dimensions, valid/invalid indices, distinct content) and an
      `iconSource` completeness/uniqueness test asserting all 36 marks map
      to their correct real-source index ranges with no gaps or
      duplicates — stronger than the old test, which only checked a flat
      0...35 range without verifying which *actual* source file backed
      each value. 85/85 total passing.
- [x] DevOps — no CI/deploy changes; resource bundling verified via a clean
      `swift build` (confirms SPM resource copy step picks up the new
      files).
- [x] Review Coordinator — process followed; `docs/domain.md`/`stack.md`
      updated with an explicit correction note (what was wrong, how it was
      found, what's now true) rather than a silent fix; `tasks/T-019.md`
      created for the ledger since this is non-trivial, shipped-code-
      touching work, not a trivial tweak.

## Lens Sign-offs (bug fix — no new major decision, but worth noting)
- [x] PM — correctly did not expand scope to also fix the darkened-variant/
      two-item-shop/HDN gaps found along the way; those are real but
      separate, already covered by existing follow-up tasks (`T-013`-`T-016`).
- [x] Builder — the manual seed-all-36-marks-then-screenshot-then-revert
      technique is a reusable pattern for verifying visual/pixel-level
      correctness when interactive UI automation (context menus) proves
      unreliable in this environment.
- Other lenses — N/A (internal bug fix, no external-facing decision).

## Regression safety
- Full suite: 85/85 passing (no test count change — same tests rewritten,
  not added/removed net).
- `swift build` clean.
- Manual verification: seeded all 36 tile marks via a temporary debug hook
  (reverted before commit — confirmed via `git diff` showing no residual
  changes to `MainTrackerPlaceholderView.swift`), screenshotted the running
  app, and pixel-matched every icon against direct crops of the real
  `ow_icons5x9.png`/`icons3x7.png` strips.

## Out of scope (tracked as follow-ons)
- `T-013`/`T-014` — item/dungeon state layer, needed for the darkened
  "already obtained" variant.
- `T-016` — HDN mode's lettered dungeon variant.
- Two-item shop display — not yet tracked as its own task; flag if wanted.
