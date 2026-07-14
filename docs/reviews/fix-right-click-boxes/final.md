# Review: fix/right-click-boxes — final (T-029)

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially. Bug-fix scope (CLAUDE.md): Backend + SDET + Ops
emphasized; other hats confirmed no impact.

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- none.

## Suggestions (consider for polish)
- none.

## Agent Sign-offs
- [x] Analyst — scope: fix the dead right-click; no behavior added. One central
      helper change; all `.onRightClick` sites benefit.
- [x] Architect — no security surface. AppKit event-routing change only.
- [x] Data Engineer — no data/model change.
- [x] Backend — root cause correct: a `.background` NSView sits behind SwiftUI's
      gesture layer and never sees `rightMouseDown`. The `.overlay` + `hitTest`
      (claim only right-mouse events, else return nil) is the canonical
      pass-through pattern; left-click/hover reach the content behind unchanged.
- [x] Frontend — single-file change in `RightClickCatcher`; the four call sites
      (dungeon `BoxView`, `BoxItemPicker`, `ItemToggleBox`, `TakeAnyHeartBox`)
      are untouched and all fixed at once.
- [x] UX — right-click "don't have it" / clear now works where it silently did
      nothing; left-click and the picker popover behave exactly as before.
- [x] Test Engineer — the event-type intercept decision is extracted to a pure
      `RightClickCatcher.intercepts` and unit-tested (right-mouse ⇒ true;
      left/hover/scroll/nil ⇒ false). The AppKit hit-test wiring itself isn't
      unit-testable, so it was verified on-device: picker right-click → orange
      "don't have it"; picker left-click → green "have it"; box left-click opens
      the picker. 236→238.
- [x] DevOps — no CI/asset change. `swift build` (debug+release) + `swift test`
      clean.
- [x] Review Coordinator — `tasks/T-029.md` filed; INDEX updated. No `docs/*`
      domain change.

## Lens Sign-offs
- Bug fix — full 7-lens not triggered.

## Regression safety
- Contracts touched = none. The catcher moved background→overlay with a
  hit-test gate; non-right events return nil so the previous pass-through
  behavior for taps/hover is preserved (and now actually reaches the content,
  which was the bug). Verified on-device that left-click still works.
- Full suite 236→238, no regressions. Builds clean (debug + release).

## Out of scope (follow-ons)
- none.
