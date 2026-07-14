# Review: feat/overlay-open-caves-money — final (T-035.2)

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats.

## Blockers
- none

## Warnings (fix before next review)
- [ ] The money overlay's priced-secret branch (`secretValue != 0`) can't
      trigger yet — no UI records a secret's rupee value. Today it resolves to
      Money-Making-Game + Unknown Secret (correct); the sized-secret case lands
      with the claimed/priced-secret model.

## Suggestions
- The open-cave toggle uses an SF Symbol (`mountain.2.fill`) since the
  reference's open-cave sprite isn't vendored. Reads clearly with the tooltip.

## Agent Sign-offs
- [x] Analyst — scope: the first two overlay toggles (open-caves + money) with
      the hover-preview/click-lock model the user specified. Zones/Coords are
      the next sub-task.
- [x] Architect — no security surface. A new `@Observable` overlay state shared
      between the chrome (icons) and the map (rendering); the map param is
      optional so nothing else needs it.
- [x] Data Engineer — money predicate matches `showLocatorRupees` (MMG /
      Unknown Secret / priced sized-secret); open-cave predicate matches
      `highlightOpenCavesCB`'s two phases (unmarked-nothingable → unclaimed
      Armos), gated on wood-sword-cave-found or sword+candle. All pure + tested.
- [x] Backend — N/A.
- [x] Frontend — `overlayToggle` icons wire `onHover`→`setHover` and
      `onTapGesture`→`toggleLock`, locked shown green; `OverworldMapView`
      draws a green border+fill for any active overlay. Shared state via a
      parent `@State`.
- [x] UX — hover previews, click pins — no checkbox clutter, per the user.
      Tooltips explain each icon. Verified on-device (open-caves lit the
      unmarked nothingable screens).
- [x] Test Engineer — 255→260: overlay state (hover/lock/active, cross-overlay
      hover), money predicate, open-cave early/late/transition. The AppKit
      hover/hit wiring isn't unit-testable; verified on-device.
- [x] DevOps — no CI/asset change (SF Symbol + existing rupee sprite). `swift
      build` (debug+release) + `swift test` clean.
- [x] Review Coordinator — `tasks/T-035.2.md` filed; INDEX updated. No `docs/*`
      domain change.

## Lens Sign-offs
- Local UI feature — full 7-lens not triggered.

## Regression safety
- Contracts touched = none. `OverworldMapView` gained an optional `overlays`
  param + a defaulted `armosClaimed`; `ItemProgressGridView` gained a required
  `overlays` (updated at its one call site). Full suite 255→260, no
  regressions. Builds clean (debug + release).

## Out of scope (follow-ons)
- **T-035.3** Zones + Coords overlays. Priced-secret value model (money overlay
  sized-secret branch; also feeds the groundhog reset's used-state revert).
