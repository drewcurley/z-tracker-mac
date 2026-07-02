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
scaling, a small set of fixed window-size presets, near-black backgrounds,
Segoe UI for body text (macOS equivalent TBD — **UNKNOWN — needs human
confirmation**, likely San Francisco or a similar system font, not
necessarily a literal Segoe UI substitute) and a Zelda-style display font for
section headers.

## Accessibility baseline

Not yet decided. Candidates worth deciding early rather than retrofitting:
VoiceOver labels for icon-only controls (the reference app is heavily
icon/gesture-driven with sparse text), keyboard-only operability (the
reference app already has an extensive hotkey system — a good foundation),
and respecting macOS "Reduce Motion" for the animation toggles already planned
(`domain.md` § 4.9 AnimateTileChanges/AnimateShopHighlights). Not blocking
initial scaffolding but should not be deferred past the first UI-bearing task.

## Update-this-doc-when

Update this file once real SwiftUI views exist and any of the above
"UNKNOWN"/"not yet decided" items are actually decided.
