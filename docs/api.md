# API — z-tracker-mac

**Status:** forward-looking / PLANNED. This app has no network API (see
`contracts.md` § 4). This doc plays the same role `api.md` plays in a networked
project — the narrative companion to `contracts.md`, explaining *how to change
the surface safely* — but the "surface" here is the **internal model-layer
boundary** between the UI-agnostic tracker model and the SwiftUI views, plus
the local file-format contracts in `contracts.md` § 1.

## 1. The internal "API": the model-layer boundary

Mirroring the reference app's proven separation (a UI-framework-agnostic F#
core that WPF/Avalonia both mutate and observe — see `architecture.md` § 2),
this project's "API surface" is the boundary between:
- **The model layer** — plain Swift types + a small number of `ObservableObject`
  classes holding all tracker state (dungeon/item/overworld/blocker/timeline/
  options state — see `domain.md` for the full field inventory this must
  eventually cover).
- **SwiftUI views** — read model state via `@ObservedObject`/`@EnvironmentObject`
  and **only** mutate it by calling model methods (e.g. `model.toggleTriforce(dungeon:)`),
  never by holding parallel view-local state that must be reconciled back.

## 2. Rules for changing this boundary safely

1. **Every user-visible tracker state field must live in the model, not a
   view.** If a view needs `@State` for something a future session or a test
   would reasonably want to assert on, it probably belongs in the model instead.
2. **Model mutations are named for the user gesture that causes them**, not
   for the underlying field (`markOverworldTile(_:as:)`, not `setMap(index:value:)`)
   — this keeps the model's public surface readable against `domain.md`'s
   gesture descriptions, and keeps `contracts.md` reviewable by a human, not
   just a diff.
3. **A model method that changes something in `contracts.md` (a save-file
   field, a hotkey-context invariant, the OBS window-title/size convention)
   is a contract change** — update `contracts.md` in the same PR, per
   `playbook/AGENTS.md` § 7.
4. **No business logic in SwiftUI view bodies.** Ports of the reference app's
   routing/room-state/blocker logic belong in the model layer (or a dedicated
   logic module the model calls), matching the reference app's own separation
   — this is what made porting the F# core straightforward to reason about in
   the first place (see ADR 0001).
5. **No silent behavior drift from the reference app.** If a ported behavior
   is intentionally changed (not a bug, a deliberate improvement), record it
   as an ADR — don't let "the clone does X differently" be discoverable only
   by diffing behavior against `Zelda1RandoTools` by hand.

## 3. Versioning / deprecation

Not applicable in the traditional sense (no external API consumers). The one
place a "breaking change" concept applies is the **save-file schema** (see
`data-model.md` § 4, compatibility decision) and the **OBS window-title/size
convention** (`contracts.md` § 2, entry 1) — both listed there, not duplicated
here.

## Update-this-doc-when

Update this file once the actual model-layer types exist — replace the
illustrative method-naming example with real method names, and add any rule
that emerges from real friction porting a specific reference-app feature.
