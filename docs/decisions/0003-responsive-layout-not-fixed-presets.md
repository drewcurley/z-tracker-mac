# ADR 0003 — Responsive, reflowing layout instead of the reference app's fixed size/zoom presets

**Status:** accepted
**Date:** 2026-07-02
**Deciders:** Drew Curley (solo; single-operator review per `playbook/AGENTS.md` §12)

## Context

The reference app (`Zelda1RandoTools`) uses a small, fixed set of window-size
presets chosen at startup — Tall (default, 768×967), Square, 2/3, 1/3, 5/6 —
plus an arbitrary size reachable only by hand-editing JSON (`docs/domain.md`
§ 4.1). The window does not reflow or resize freely at runtime; the developer
(who has used the reference app extensively) has always found this a
frustrating limitation, not a feature worth preserving.

This project's stated goal is "feature-by-feature, near pixel-perfect clone,"
which by default would mean cloning this behavior too. This ADR records an
explicit, deliberate exception rather than silently drifting from parity.

## Decision

**`z-tracker-mac` will be responsive and reflow as the window is resized**,
not restricted to the reference app's fixed size/zoom presets. This is a
deliberate parity deviation, not an oversight — `docs/domain.md` § 4.1 is
annotated to point here rather than edited to pretend the reference app
always worked this way.

What this means concretely for the startup-screen task and beyond:
- No hardcoded pixel dimensions for the main window. SwiftUI layout containers
  (`VStack`/`HStack`/`Grid`/`GeometryReader` where genuinely needed) reflow
  content as the window resizes, down to a sensible minimum and up to a
  sensible maximum (exact bounds are a UI-implementation detail, not a
  product decision — decide those when building the actual layout, don't
  guess here).
- The overworld map, dungeon grids, and item icons — everything currently
  sprite-sheet-rendered at a fixed small size in the reference app — must
  scale with available space rather than clip or leave dead space. This is a
  materially harder rendering problem than the reference app's fixed-size
  approach and directly informs the `Canvas`-based sprite-rendering plan in
  ADR 0002: sprite drawing code must take a target size, not assume a fixed
  one.
- The **broadcast window** (`contracts.md` § 2 entry 1) is the one deliberate
  exception: OBS "Window Capture" works best against a stable, predictable
  size, so the broadcast window keeps fixed-size presets (or a fixed
  aspect-ratio resize) even though the main tracker window is responsive.
  This is worth restating explicitly so a future task doesn't "fix" the
  broadcast window into matching the main window's free-resize behavior.

## Consequences

**Good:**
- Directly addresses a real, specific frustration the developer has with the
  original tool, rather than faithfully reproducing something disliked just
  because "clone" was the instruction — the developer explicitly called this
  out as an intentional divergence, not scope creep.
- A responsive layout is generally friendlier across different Mac screen
  sizes without needing N discrete presets to approximate "friendly."

**Bad / accepted trade-offs:**
- Materially more implementation work than fixed-size layouts: every view
  needs to behave sensibly across a range of sizes, not just at 5 known
  points. This is accepted as core scope, not deferred, since it shapes the
  UI architecture from the first feature task (the startup screen) onward.
- Sprite rendering at arbitrary sizes makes the reference app's crisp
  nearest-neighbor-at-fixed-scale approach harder to preserve exactly —
  likely needs integer-scale snapping (round the render scale to the nearest
  whole multiple of the sprite's native size) to keep pixel-art crispness
  while still being responsive. Not fully designed here — flagged as a
  concrete open problem for whichever task first renders a sprite atlas.
- The broadcast-window exception means "responsive" is not a blanket, no-exceptions
  rule — future tasks must check which window they're building before assuming
  free resize is always correct.

## Notes

`docs/domain.md` § 4.1 keeps its original, grounded description of the
reference app's fixed presets (that's a historical fact about the reference
app, not something to rewrite) with a pointer to this ADR marking it as an
intentional non-parity item. `docs/ux.md` is updated in the same change to
state the responsive-design principle as part of this project's actual design
system, not the reference app's.
