# UX — z-tracker-mac

**Status:** forward-looking, grounded in the reference app's proven UX
(no UI exists in this repo yet). See `domain.md` for the exhaustive feature/
gesture inventory this summarizes at a higher level.

## Personas (carried forward from the reference app, `Zelda1RandoTools/README.md`)

1. **Seed runner** — needs the fastest, least-intrusive gesture set for
   entering state while actively playing. Primary success metric: never
   fumbling the tracker costs in-game time or attention.
2. **Stream viewer** — never touches the app directly. Needs the on-screen
   state (main window or the dedicated broadcast window) to communicate
   "where is the runner right now, and how did they get here" at a glance,
   including for someone arriving mid-stream.
3. **z1r learner** — benefits from routing assistance and reminder nudges that
   a seasoned runner might turn off.

## Primary journeys

1. **Start a seed** — startup screen → pick quest type/options → main tracker
   view, ready for input within seconds (this app must never be the bottleneck
   between "seed generated" and "starting the run").
2. **Track progress during a run** — the bulk of interaction: marking overworld
   tiles, toggling dungeon items, updating room state — all via fast
   click/scroll/hotkey gestures, ideally without looking away from the game
   for more than a glance (per the reference app's own stated design goal).
3. **Recover from a crash/restart** — reopen the app, load from autosave,
   continue with minimal lost state.
4. **Stream a run** — open the broadcast window, position/size it for OBS,
   let it run hands-off (see `contracts.md` § 2 entry 1 for the window
   title/size contract this depends on).

## Design-system pointers

Not yet established — no SwiftUI views exist yet. The reference app's visual
language (see `domain.md` § "Notable for a pixel-perfect clone" in the
inventory that produced this doc set, and ADR 0001) is the starting point:
sprite-sheet pixel art at small native sizes with integer/nearest-neighbor
scaling, near-black backgrounds, Segoe UI for body text (macOS equivalent TBD
— **UNKNOWN — needs human confirmation**, likely San Francisco or a similar
system font, not necessarily a literal Segoe UI substitute) and a Zelda-style
display font for section headers.

**Layout is responsive, not fixed-preset — a deliberate departure from the
reference app** (`docs/decisions/0003-responsive-layout-not-fixed-presets.md`).
The reference app's small set of fixed window-size presets (Tall/Square/2:3/
1:3/5:6) is a specific, longstanding frustration for the developer, not a
behavior worth cloning. The main tracker window reflows as it's resized;
sprite-rendered content (overworld map, dungeon grids, item icons) must scale
with available space, likely via integer-scale snapping to keep pixel-art
crispness at arbitrary window sizes (open implementation problem, not solved
yet). The **broadcast window is the one exception** and keeps the reference
app's fixed sizing, since OBS window capture wants a stable size.

## Accessibility baseline

**Decided (T-067).** This app is heavily icon/gesture-driven, so VoiceOver
support is not automatic — a plain `.onTapGesture` view is invisible to
VoiceOver (confirmed by inspecting the AX tree). The convention, applied across
all interactive views and required for every new one:

- **Custom-gesture controls** (`.onTapGesture` / `Rectangle`-backed tiles, boxes,
  labels): make each a single accessibility element —
  `.accessibilityElement(children: .ignore)` + `.accessibilityLabel(...)` (what
  it is) + `.accessibilityValue(...)` (its current state) +
  `.accessibilityAddTraits(.isButton)` + `.accessibilityAction { primary }`.
  Add `.accessibilityAction(named:)` for secondary gestures (e.g. a right-click
  picker). Reference implementations: the overworld `TileView`
  (`OverworldMapView.swift`) and the dungeon `BoxView` / `HintLabel` /
  `DungeonNumberLabel`.
- **Icon-only standard controls** (a `Button`/`Toggle` whose label is only an
  `Image`, or `Toggle("", …)`): add an explicit `.accessibilityLabel(...)`
  (and `.accessibilityValue(...)` for state). Text-labeled buttons need nothing.
- **Purely decorative layers** (terrain sprites, the faux HUD image, glows):
  `.accessibilityHidden(true)` — keeps the AX tree small and VoiceOver focused.
- **Reduce Motion**: honor `@Environment(\.accessibilityReduceMotion)` /
  `.animation(nil)` where animations are added (ties into the AnimateTileChanges
  / AnimateShopHighlights toggles, `domain.md` § 4.9).

Note: SwiftUI's `.accessibilityIdentifier` does **not** bridge to the AppKit AX
interface that `System Events` scripting reads (confirmed on-device), and an
auto-generated `Button`'s label doesn't either — but an *explicit*
`.accessibilityElement()` + `.accessibilityLabel()` does. This is why AX
scripting can only target our controls once they carry explicit accessibility
elements; XCUITest (a separate interface) would read identifiers directly.

## Update-this-doc-when

Update this file once real SwiftUI views exist and any of the above
"UNKNOWN"/"not yet decided" items are actually decided.
