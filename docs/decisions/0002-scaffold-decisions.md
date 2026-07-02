# ADR 0002 — Scaffold decisions: deployment target, save location, test framework, sprite rendering

**Status:** accepted
**Date:** 2026-07-02
**Deciders:** Drew Curley (solo; single-operator review per `playbook/AGENTS.md` §12)

## Context

`tasks/T-002.md` (initial SwiftPM scaffold) explicitly required resolving
several items `stack.md`/`data-model.md` had left as `UNKNOWN — needs human
confirmation` rather than guessed during the docs bootstrap. Resolving them
now, grounded in what actually built and ran during the scaffold work.

## Decisions

1. **Minimum deployment target: macOS 14 (Sonoma).** Set in `Package.swift`
   (`platforms: [.macOS(.v14)]`). This is a greenfield app with one user
   (the developer) initially — no installed-base constraint favors an older
   floor, so the newest well-established SwiftUI/Observation APIs win.
   Revisit only if distributing to others with older machines becomes a real
   constraint.

2. **Save/settings directory: `~/Library/Application Support/com.drewcurley.ztrackermac/`.**
   Implemented as `TrackerCore.SaveDirectoryLocator`. This is the standard
   macOS location for app-owned data (contrast with the reference app writing
   next to its own executable, not viable for a signed/notarized app bundle —
   see `docs/data-model.md` § 1). Bundle identifier `com.drewcurley.ztrackermac`
   is also now the app's identity for future signing/entitlements work.

3. **Unit test framework: Swift Testing (`import Testing`, `@Test`/`@Suite`),
   not XCTest**, superseding what `docs/testing.md` originally said. Decided
   once the toolchain was in hand (Swift 6.3, Xcode 26.6): Swift Testing is
   the current first-party successor to XCTest for unit-level tests, with
   better parameterized-test ergonomics (used directly in
   `TrackerModelTests.selectQuestSetsQuest`, one test covering all four
   `OverworldQuest` cases). **XCTest / XCUITest remains the choice for UI-level
   end-to-end tests** — Swift Testing does not replace XCUITest. `testing.md`
   is updated in this same change to reflect this; it is not left to drift.

4. **Sprite rendering: SwiftUI `Canvas` + `CGImage` cropping, no AppKit
   interop for v1.** Not yet implemented (no sprite work in this scaffold),
   but decided here to unblock the next feature task rather than leaving it
   open indefinitely. `Canvas` (available since the deployment target chosen
   in #1) supports drawing pre-cropped `CGImage` regions from the sprite-sheet
   atlases with interpolation disabled for crisp nearest-neighbor scaling —
   the reference app's core visual requirement (`docs/domain.md` § "Notable
   for a pixel-perfect clone"). `NSViewRepresentable`/AppKit interop is
   deferred, not ruled out — if a future prototype shows `Canvas` can't hit
   the required frame rate or pixel exactness for the dungeon-grid painting
   gestures, revisit with a new ADR rather than silently switching approaches.

## Consequences

**Good:**
- Every "UNKNOWN" the docs bootstrap deliberately left open is now resolved
  with a real, verified artifact (the scaffold builds, runs, and tests pass)
  rather than a guess.
- Swift Testing's parameterized tests already paid off in the very first test
  file (`TrackerModelTests`), one test covering all 4 quest variants instead
  of 4 near-duplicate XCTest methods.

**Bad / accepted trade-offs:**
- Swift Testing is newer than XCTest and has a smaller body of community
  troubleshooting material — acceptable for a solo project prioritizing
  ergonomics now over precedent.
- The sprite-rendering decision (#4) is made without a working prototype —
  flagged explicitly as revisitable, not treated as settled-forever.

## Notes

Supersedes the relevant "UNKNOWN" lines in `docs/stack.md` and
`docs/data-model.md`, which are updated in the same change as this ADR per
`playbook/AGENTS.md` § 7 (docs and the change that resolves them land together).
