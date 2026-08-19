# Review: chore/credit-procnoviach — final (T-204)

**Status:** PASS — the app credits now name the Mac version's author (procnoviach) next to the
original-port credit, on both the start screen and Settings.

unanimous-consensus: T-204

## What shipped
- `SettingsPanelView` About text: "Mac version by procnoviach — a native port of the original
  Windows Z-Tracker (F#) by Brian McNamara." Shared by `StartupView` + the Settings window.

## Sign-offs
- [x] Analyst — matches the ask; covers both requested surfaces via the shared view.
- [x] Frontend / UX — one line, same style; renders on start screen + Settings.
- [x] SDET — no test pins the credit string; **730 tests pass**; clean build.
- [x] Architect / Backend / Data / DevOps — n/a (a static string).
- [x] Review Coordinator — task filed (T-204); INDEX updated.

## Items to address (follow-ups)
- No release cut (per user); rides the next release. The README Credits section could name
  procnoviach too for consistency — offered, not done unless wanted.
