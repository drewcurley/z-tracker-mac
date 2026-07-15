# Review: feat/start-spot — final (T-035.8)

**Status:** PASS

unanimous-consensus: T-035.8

## Summary
A placeable start-spot marker: `TrackerModel.startSpot` (optional coordinate,
ported from `startIconX/Y`) rendered as a lime ring on a violet glow, set/cleared
from the tile context menu. Independent of the tile's mark; auto-mirrors with the
map.

## Sign-offs
- [x] Analyst — delivers the reference's start-spot marker. Placement via the
      existing tile menu instead of a modal mode (simpler, discoverable); the
      post-reset auto-prompt is out of scope.
- [x] Architect — no security surface.
- [x] Data Engineer — one optional coordinate; no persistence yet (save is a
      later task and already lists StartIconX/Y).
- [x] Backend — trivial set/clear via closures.
- [x] Frontend — a non-hit-testing ring overlay keyed on the tile coord;
      context-menu item toggles set/clear based on whether this tile is the spot.
- [x] UX — the lime/violet ring matches the reference icon; right-click → "Set
      as start spot" is discoverable alongside the mark options.
- [x] Test Engineer — view-only marker over trivial state; 324/324 pass, build
      clean; rendering verified on-device.
- [x] DevOps — no infra/deps.
- [x] Review Coordinator — task filed (T-035.8); INDEX regenerated.

## Regression safety
- Additive model field + two gated overlays + one menu entry. Nothing renders
  unless a start spot is set. Full suite 324/324, build clean. On-device: the
  ring renders on the chosen tile.
