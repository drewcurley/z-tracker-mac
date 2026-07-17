# Review: feat/hotkey-editor — final (T-130 / T-131)

**Status:** PASS — hotkey editor + config (Part A). Keys don't fire yet (Part B).

unanimous-consensus: T-130
unanimous-consensus: T-131

## Sign-offs
- [x] Analyst — Part A scope agreed (editor + import/export only); dispatch deferred.
- [x] Architect — pure model in TrackerCore; editor in ZTrackerMac; `HotkeyConfig`
      hoisted like other app-level state; conflict-as-move is the invariant
      (docs/contracts.md § 2 entry 6).
- [x] Data — catalog ids transcribed from the reference `HotKeys.txt`; round-trip
      test proves export→parse fidelity; conflict scopes encode the reference rules.
- [x] Frontend — grouped editor, local key-event capture, reassign dialog, filter,
      import/export pickers, Settings entry point, dedicated window.
- [x] UX — Global first (protected from accidental displacement); reassign names the
      binding it removes; Command reserved for menus. User-QA'd on-screen.
- [x] Backend — persistence via the exported text in UserDefaults.
- [x] SDET — 11 hotkey assertions (catalog/parse/conflict/reassign/order/round-trip).
      502 tests pass; build clean.
- [x] DevOps — no infra impact.
- [x] Review Coordinator — tasks filed (T-130, T-131); INDEX updated.

## Regression safety
- Additive feature; no existing behavior touched. Keys are inert until Part B.
