# Review: feat/overworld-chooser-ux — final (T-205)

**Status:** PASS — F16 coast-item picker, live chooser hover label, and graphical chooser
on by default. All three QA'd on device (user: "both look good").

unanimous-consensus: T-205

## What shipped
- Left-click **F16** (col 15, row 5) opens the coast-item picker (`ladderBox`) directly;
  T-106 prompt generalized to `PromptBox {armos, whiteSword, coast}`; deferred a runloop tick
  so the popover actually presents.
- Graphical chooser header shows the hovered icon's label **live** (no tooltip delay).
- `graphicalOverworldChooser` default → **true** (fresh installs; persisted choice preserved).

## Sign-offs
- [x] Analyst — three scoped user requests; right-click still marks F16 normally.
- [x] Architect — coast reuses the existing prompt/box machinery; default flip is additive
      and respects persisted settings.
- [x] Backend / Frontend — deferred-popover matches the working Armos path; hover clear-on-exit
      is race-safe.
- [x] UX — live label removes the tooltip lag; coast picker is one click on its fixed screen.
- [x] SDET — coast-coordinate guard test (`coastColumn/Row` → "F16"); **732 pass**.
- [x] DevOps — clean build/test; `VERSION` → 0.8.4; both DMGs re-cut.
- [x] Data / Review Coordinator — n/a schema; task filed (T-205); INDEX updated.

## Items to address (follow-ups)
- The coast popover anchors to the right edge (F16 is the rightmost column); macOS repositions
  it to fit — verified acceptable on device.
