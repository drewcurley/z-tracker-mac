# Review: feat/overlay-zones-coords — final (T-035.3)

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — routine UI over
ported static data, reusing the T-035.2 overlay infrastructure.

## Blockers
- none

## Warnings (fix before next review)
- [ ] The reference draws white boundary lines between zones; this tints only
      (the distinct colors already read as regions). A refinement.
- [ ] Coords use the non-mirrored numbering; the reference flips columns
      (`16-i`) under MirrorOverworld — folds in with T-015.7.

## Agent Sign-offs
- [x] Analyst — scope: the last two overlay toggles (Zones + Coords), same
      interaction model. Finishes the T-035 overlay set.
- [x] Architect — no security surface; two more enum cases + two pure data
      sources (`OverworldZones`, `OverworldCoords`), no new state.
- [x] Data Engineer — `owMapZone` transcribed verbatim (8×16, only the 10 known
      letters — asserted); colors match `UIComponents.fs`; the coord format is
      pinned by the "F16" coast test.
- [x] Backend — N/A.
- [x] Frontend — two `.overlay`s on the tile (a translucent zone tint; a coord
      label), gated on `overlays?.isActive`. Two `overlayToggle` icons reuse the
      existing hover/click wiring.
- [x] UX — Zones color-codes the regions; Coords labels each screen legibly
      (monospaced, shadowed). Verified on-device.
- [x] Test Engineer — 260→264: zone grid shape + letter set, representative zone
      lookups + out-of-range nil, every-letter-has-a-color, coord format incl.
      A1 / H16 / the F16 coast.
- [x] DevOps — no CI/asset change (SF Symbols + ported data). `swift build`
      (debug+release) + `swift test` clean.
- [x] Review Coordinator — `tasks/T-035.3.md` filed; INDEX updated. No `docs/*`
      domain change.

## Regression safety
- Contracts touched = none. Additive enum cases + tile overlays; existing
  overlays unaffected. Full suite 260→264, no regressions. Builds clean.

## Out of scope (follow-ons)
- Zone boundary lines; mirror-flipped coords (T-015.7); **T-035.4** timer /
  spot summary / FQ-SQ.
