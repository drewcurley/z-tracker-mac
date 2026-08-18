# Review: feat/in-menu-hotkey-hints — final (T-197)

**Status:** PASS — bound hotkeys now show inline in the overworld tile menu and the hint-zone
picker (coverage §1 #3b, the last HotKeys sliver). QA'd on device.

unanimous-consensus: T-197

## What shipped
- `HotkeyHints` (TrackerCore): mark/zone → `HotKeys.txt` selector, then the bound chord as an
  inline suffix `" (B)"` / bare badge `"B"`; derived from the catalog (no duplicate mapping).
- `HotkeyConfig` injected via the SwiftUI environment; consumed by the tile menus (SwiftUI +
  native) and the hint-zone picker.

## Sign-offs
- [x] Analyst — closes §1 #3b; reference-grounded (`AppendHotKeyToDescription`).
- [x] Architect — environment injection avoids wide plumbing; helper is pure/catalog-derived.
- [x] Data — n/a (no persistence change).
- [x] Backend — labels compose the suffix; unbound → empty, no behavior change.
- [x] Frontend / UX — hints read at menu scale and in the picker; default bindings make them
      visible out of the box; verified on device.
- [x] SDET — `HotkeyHintsTests` (mapping + formatting); **730 pass**.
- [x] DevOps — clean build/test; `.app` rebuilt for QA.
- [x] Review Coordinator — task filed (T-197); INDEX updated.

## Items to address (follow-ups)
- The overworld keys are hover-context (not press-in-menu); the hint teaches the hover key.
  If that reads as confusing in practice, the suffix wording is a one-line change.
