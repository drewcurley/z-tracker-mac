# Review: fix/chrome-cleanup — final (T-033)

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — bug-fix/polish tier;
two small UI changes from direct user feedback.

## Blockers
- none

## Warnings
- [ ] Max Hearts is now display-only in the chrome; the starting-hearts
      *differential* (`maxHeartsDifferential`) is still adjustable only via the
      temporary debug panel. Acceptable — the user said max hearts should be
      program-computed, not hand-edited.

## Agent Sign-offs
- [x] Analyst — scope: exactly the two feedback items (read-only Max Hearts;
      labels → tooltips). No behavior change beyond removing the editing control.
- [x] Architect — no security/model surface; a view-only change.
- [x] Data Engineer — Max Hearts already read the derived `playerHearts`; only
      the input control was removed, so the value is unchanged and dynamic.
- [x] Backend — N/A.
- [x] Frontend — dropped the `Stepper`/`MaxHeartsControl`; `maxHeartsReadout`
      is a plain `Text`. The three toggles use `iconOnly` (icon + `.help`
      tooltip), no visible text — matching the reference's icon-only checkboxes.
      Chrome laid out as one row.
- [x] UX — cleaner chrome per the user's preference (labels as tooltips); Max
      Hearts reads as a live number the player can't accidentally edit. Take-any
      hearts remain tooltip-only.
- [x] Test Engineer — no logic touched; 250/250 unchanged. On-device verified
      the icon-only toggles, read-only Max Hearts, and take-any tooltip.
- [x] DevOps — no CI/asset change. `swift build` (debug+release) + `swift test`
      clean.
- [x] Review Coordinator — `tasks/T-033.md` filed; INDEX updated. No `docs/*`
      domain change.

## Regression safety
- Contracts touched = none. Removed an editing control + visible labels; the
  toggles' bindings and the Max Hearts value are unchanged. Full suite 250/250.
  Builds clean (debug + release).

## Out of scope
- Moving `maxHeartsDifferential` out of the debug panel (once the debug panel is
  replaced by the real starting-items editor).
