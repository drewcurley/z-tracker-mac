# Architecture — z-tracker-mac

**Status:** forward-looking. No code exists yet (`tasks/T-002.md` covers initial
scaffold). This describes the intended design, grounded in the reference app's
proven architecture (see Verification), not the current state of this repo.

**Verification:** the design here mirrors the architecture pattern found in
`Zelda1RandoTools` by direct source inspection (F# `.fsproj`/`.fs` files) via a
dedicated inventory pass, 2026-07-02 — see `domain.md` for the full report and
citations. See `docs/decisions/0001-native-swiftui-over-avalonia-port.md` for
why this is a from-scratch native rewrite rather than a port.

## 1. What this app is

A **local, single-user, offline desktop utility** — a manual game-progress
tracker for Zelda 1 Randomizer (z1r) seeds. It is not a game, has no backend,
no network service, no accounts, and (confirmed by inventory: no
`ReadProcessMemory`/RAM access in the reference app) **no emulator memory
integration** — every piece of tracked state is entered by the user clicking,
scrolling, or pressing hotkeys. The only cross-process behavior in the
reference app is optional, passive window-title scanning to auto-fill a
seed/flags label (`SnoopSeedAndFlags`) — not a dependency this design requires.

## 2. High-level shape

```
┌─────────────────────────────────────────────────────────────┐
│                      z-tracker-mac (SwiftUI app)              │
│                                                               │
│  ┌───────────────────┐        ┌────────────────────────────┐ │
│  │   TrackerModel     │◄──────►│   SwiftUI Views            │ │
│  │  (UI-agnostic)     │ pub-   │  (Overworld map, Dungeon   │ │
│  │  - item/dungeon     │ lishes │   grid, Item boxes, Popups,│ │
│  │    state            │ via    │   Timeline, Options, …)    │ │
│  │  - overworld tiles   │ Combine/│                            │ │
│  │  - blockers          │ Observ-│  Gestures write back to    │ │
│  │  - timeline events   │ ableObj│  the model; views never    │ │
│  │  - options           │ ect    │  own state themselves.     │ │
│  └─────────┬─────────┘        └────────────────────────────┘ │
│            │                                                  │
│            ▼                                                  │
│  ┌───────────────────┐        ┌────────────────────────────┐ │
│  │  Persistence        │        │  Platform integrations      │ │
│  │  (local JSON files, │        │  - AVSpeechSynthesizer      │ │
│  │   see data-model.md)│        │  - SFSpeechRecognizer       │ │
│  │  - autosave          │        │  - GameController (gamepad)│ │
│  │  - manual save        │        │  - Broadcast window (OBS   │ │
│  │  - options settings   │        │    passive window capture) │ │
│  └───────────────────┘        └────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

This directly mirrors the reference app's proven separation: a UI-framework-
agnostic core (`Z1R_Tracker`, six F# files: `OverworldData.fs`, `DungeonData.fs`,
`TrackerModelOptions.fs`, `TrackerModel.fs`, `OverworldRouting.fs`,
`SaveAndLoad.fs`) that the WPF UI mutates and observes via change-events. The
Swift equivalent: a single UI-agnostic model layer (Swift structs/enums +
one or a small number of `ObservableObject`s) that SwiftUI views read via
`@ObservedObject`/`@EnvironmentObject` and mutate only through model methods —
never by mutating view-local state that then needs reconciling back.

## 3. Trust boundaries / security model

There are effectively none in the traditional sense — this is not a networked
or multi-tenant system:
- **No network calls, no backend, no accounts/auth.** Confirmed: the reference
  app has zero network I/O; this design carries the same posture forward.
- **Local file I/O only**: reading/writing save files and an options-settings
  file in the app's own data directory (see `data-model.md`); optionally
  reading user-provided custom assets (extra icons, a "show/run custom" file
  that can **launch external executables/URLs** — see `contracts.md` for the
  one genuinely security-relevant surface: local arbitrary-process launch is
  a deliberate power-user feature in the original, not a bug, but is a redline
  item the Architect hat must consider explicitly before implementing).
- **OBS integration is entirely passive** (window title + fixed pixel
  dimensions for crisp capture) — no socket, no API, nothing this app
  initiates or exposes.

## 4. Data flow

1. User launches app → startup screen (quest type, options) → main tracker view.
2. User gesture (click/scroll/hotkey/speech) → dispatched to the model layer →
   model mutates its published state → SwiftUI views re-render from that state.
3. Model periodically (and manually, and on "finished") serializes itself to a
   local JSON file — see `data-model.md` for the three save types and exact
   schema (ported from the reference app's format; compatibility decision
   still open, see `data-model.md` § open questions).
4. Optional: model changes trigger reminders (spoken via `AVSpeechSynthesizer`,
   and/or a visual log) and optional speech-recognized voice commands mutate
   the model the same way a click would.

## 5. What this design deliberately does NOT include

- No emulator/ROM memory reading of any kind (matches the reference app).
- No network layer, no update-check phone-home (unless a later ADR adds one
  for app auto-update — not decided; see `deployment.md`).
- No multi-window-server or plugin architecture — "extra windows" (broadcast,
  pop-outs, hotkey cheat sheet) are additional `NSWindow`/SwiftUI `WindowGroup`
  instances reading the same shared model, not separate processes.

## Update-this-doc-when

Update this file the moment the Xcode/SPM scaffold lands and the model
layer's actual type/module boundaries are chosen — replace the "forward-looking"
diagram with real type names and file paths, matching the standard this doc
holds itself to (§ 6.0 grounding).
