# Review: fix/sword-hint-placement — final (T-040)

**Status:** PASS — layout fix; bug-fix tier.

## Sign-offs
- [x] Analyst — scope: correct the two sword-hint label positions.
- [x] Frontend — the hint row now reserves a fixed-width slot per column
      (`Color.clear` for empties), so col 1 (White Sword item box) and col 2
      (Magical Sword box) hold the labels without the empty slots collapsing.
- [x] UX — each sword hint sits directly over its box, as intended.
- [x] Test Engineer — 274/274 unchanged (view-only). On-device verified.
- [x] DevOps / Architect / Data / Backend — N/A / clean.
- [x] Review Coordinator — task filed; INDEX updated.

## Regression safety
- View-only; contracts untouched. Full suite 274/274.
