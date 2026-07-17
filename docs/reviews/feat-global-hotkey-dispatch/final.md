# Review: feat/global-hotkey-dispatch — final (T-132)

**Status:** PASS — Global hotkeys fire at runtime (Part B phase 1).

unanimous-consensus: T-132

## Sign-offs
- [x] Analyst — proves the dispatch pipeline; scope limited to Global actions.
- [x] Architect — local event monitor scoped to the main window + guarded against
      text editing; reverse lookup in the pure config; dispatcher owns no state.
- [x] Data — `selectorID(boundTo:in:)` reverse lookup tested.
- [x] Frontend — dispatcher installed on the main view's appear/disappear; shared
      `HotkeyChord(nsEvent:)`.
- [x] UX — keys don't hijack typing; user-confirmed toggle on/off.
- [x] Backend — actions map to existing model/timer mutations.
- [x] SDET — reverse-lookup test; dispatch is AppKit-coupled (manual QA). 503 tests pass.
- [x] DevOps — no infra impact.
- [x] Review Coordinator — task filed (T-132); INDEX updated.

## Regression safety
- Additive; monitor only consumes events it maps to a bound Global action. Unbound /
  unimplemented keys pass through untouched.
