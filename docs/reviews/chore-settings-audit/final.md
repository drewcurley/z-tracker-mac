# Review: chore/settings-audit — final (T-206)

**Status:** PASS — audited the 12 no-consumer settings; nixed 4, hid 3, wired 3 (each decided
with the user). Two more became their own build tasks (T-207 animate, T-208 sounds).

unanimous-consensus: T-206

## What shipped
- **Nixed:** Show basement info, Animate shop highlights, Snoop/Display seed&flags — removed
  from `TrackerOptions`, the Settings UI, and tests.
- **Hidden:** Show magnifier, Mouse magnifier window, Left-drag auto-inverts — settings line
  commented out; option kept.
- **Wired:** Hide timer (suppress `TimerView`), Default to NonDescript (threaded `defaultRoom`
  through the gesture/map + `preferNonDescript` through the views), Listen for speech
  (auto-start voice once at launch).

## Sign-offs
- [x] Analyst — every change traces to an explicit per-item user decision.
- [x] Architect — `defaultRoom`/`preferNonDescript` threaded exactly like `inferDoors`; no
      new global state; removed options gone cleanly (no dangling refs — build proves it).
- [x] Backend / Frontend — one call site each; auto-listen guarded to fire once, mic-permission
      friendly.
- [x] UX — settings screen no longer shows dead toggles; the three wired ones now do something.
- [x] SDET — gesture default-room override test; removed invalid assertions; **733 pass**.
- [x] DevOps / Data — n/a; clean build/test.
- [x] Review Coordinator — task filed (T-206); INDEX updated.

## Items to address (follow-ups)
- Animate tile changes (T-207) and confirmation sounds (T-208) are the buildable items from
  this audit.
