# ADR 0001 — Native Swift/SwiftUI rewrite, not a port of the existing Avalonia build

**Status:** accepted
**Date:** 2026-07-02
**Deciders:** Drew Curley (solo; single-operator review per `playbook/AGENTS.md` §12)

## Context

Z-Tracker (`Zelda1RandoTools`) already has **four** F# projects, one of which
(`Z1R_Avalonia`) targets Avalonia — a cross-platform XAML-like UI framework that
can run on macOS. Before building anything new, the obvious alternative to a
from-scratch rewrite is: get the existing Avalonia project running on macOS.

Findings from a full codebase/doc inventory (see `domain.md` for the complete
report):
- `Z1R_Avalonia` targets `netcoreapp3.1` (EOL) and Avalonia `0.10.3` — several
  major versions behind current Avalonia.
- Its companion core re-packaging, `Z1R_Tracker_NETCoreApp31`, compiles only
  4 of the 6 core F# files — it **omits `TrackerModelOptions.fs` and
  `SaveAndLoad.fs`**. The Avalonia build has no options-persistence and no
  save/load path equivalent to the WPF app's.
- No release has ever shipped a current macOS build; the only cross-platform
  release was v1.0 (2021), years behind the current v1.3.1 feature set. The
  project's own docs (`about.md`) frame Avalonia as "the Linux port for one
  user," not an actively maintained parity target.
- The user's explicit requirement is a **native** Apple Silicon macOS app —
  Avalonia is cross-platform but not native (it does not use AppKit/SwiftUI;
  it brings its own rendering and widget model).

Three options considered:
- **A. Resurrect and finish the Avalonia build.** Upgrade Avalonia/`net` version,
  port the missing save/load + options code from the WPF app, add the ~2 years
  of WPF-only features (per `whats-new.md`) that never reached Avalonia, then
  build for macOS. Fastest to a "something runs" milestone, but produces a
  cross-platform app, not a native one — doesn't meet the stated requirement —
  and inherits an unfamiliar, stale toolchain (F#/.NET on macOS) with no
  first-party UI framework fit for "pixel-perfect" fidelity control.
- **B. Native Swift/SwiftUI rewrite, porting the F# core's logic 1:1.** Meets
  the "native Apple Silicon" requirement directly. The F# core
  (`OverworldData.fs`, `DungeonData.fs`, `TrackerModelOptions.fs`,
  `TrackerModel.fs`, `OverworldRouting.fs`, `SaveAndLoad.fs`) is already
  UI-framework-agnostic — confirmed no WPF/Avalonia references in it — so it
  is a clean logic spec to port to a Swift model layer, independent of the
  original UI code. Slower to first milestone than A, but is the actual ask.
- **C. Some other cross-platform toolkit (Flutter, Electron, etc.).** Rejected
  outright — none are "native," and Electron in particular is a poor fit for a
  low-latency, always-on-top tracker overlay meant to sit beside an emulator
  window.

## Decision

**B — native Swift/SwiftUI rewrite.** Port the F# core's logic 1:1 (it is
already a clean, UI-agnostic spec — see `domain.md` for the exhaustive feature
inventory extracted from it and from the WPF UI, which is the newest and most
complete behavioral reference). Do not attempt to resurrect or build on
`Z1R_Avalonia`.

Sprite/icon assets: `Zelda1RandoTools` is MIT-licensed (confirmed by reading
`LICENSE.txt`), which permits reuse/modification with attribution. The plan is
to **reuse the existing sprite-sheet PNGs** (`Z1R_Tracker/Z1R_WPF/icons/*`)
rather than redraw them from scratch, crediting Brian McNamara per the license
in `z-tracker-mac`'s README/NOTICE. This is a pixel-perfect-fidelity win and a
legally clean one. **Not yet decided:** whether any assets will eventually be
redrawn at higher resolution for Retina displays — tracked as an open item in
`domain.md`, not blocking initial work.

Because the app also visually depicts Zelda 1 items/enemies (Nintendo IP,
distinct from Brian McNamara's original tracker-icon artwork), this project
follows the same widely-practiced convention as the broader z1r
tracker/randomizer community (ZHelper, EmoTracker packs, etc.): a free,
non-commercial fan tool. This is not a legal clearance, just a documented,
consistent-with-precedent posture — flagged here rather than silently assumed.

## Consequences

**Good:**
- Meets the explicit "native Apple Silicon" requirement with a first-party
  Apple UI framework, giving full control over pixel-perfect rendering,
  integer-scaling behavior, and hardware-accelerated compositing (relevant
  given the original's own noted `BlurEffect` performance caveat).
- The F#-core-as-spec approach means feature parity work has an exact,
  code-grounded reference to port against, not a from-memory reimplementation.
- Reusing the original sprite assets under MIT license gets pixel-perfect
  fidelity for free and legally, rather than needing to redraw ~dozens of
  sprite-sheet atlases from scratch before any UI work can start.

**Bad / accepted trade-offs:**
- Slower to a "something runs" milestone than porting/finishing the Avalonia
  build would have been — accepted because "native" was explicit and
  non-negotiable in the request, not a nice-to-have.
- No shared code with the original whatsoever (different language entirely) —
  every behavior must be re-verified against the F# source and the WPF UI
  behavior rather than inherited by compiling shared code. Mitigated by the
  exhaustive `domain.md` inventory and by treating `contracts.md` as the
  living parity checklist.
- Several original integrations have no direct macOS equivalent and need a
  platform-appropriate substitute, each an open item in `domain.md`/`contracts.md`:
  `System.Speech` (synthesis + recognition) → macOS `AVSpeechSynthesizer` +
  `SFSpeechRecognizer`; `SharpDX.DirectInput` (gamepad) → macOS `GameController`
  framework; Windows `.lnk` shortcut creation → not applicable on macOS.

## Notes

Supersede — never edit — this record if the stack choice changes (e.g., if a
future decision revisits cross-platform tooling). Minimum macOS deployment
target and exact SwiftUI/AppKit split are recorded in `stack.md`, not here.
