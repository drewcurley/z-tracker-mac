# Review: feat/left-drag-auto-invert — final (T-253)

**Status:** PASS — single-operator review (audit §4 follow-up; user-directed scope).

unanimous-consensus: T-253

## Sign-offs
- [x] Analyst — builds exactly the reference invert + auto-invert; cosmetic drag extras out of scope.
- [x] Architect — n/a for this change.
- [x] Data — n/a for this change.
- [x] Backend — invert/beginDrag on DungeonRoomMap, session-only flag.
- [x] Frontend / UX — deferred plain-left only while armed, so normal clicking keeps its instant feel; awaiting user visual QA.
- [x] SDET — invert, arming, disarm, middle default-room tests; 864 pass.
- [x] DevOps — n/a for this change.
- [x] Review Coordinator — T-253 filed; INDEX + CHANGELOG updated.
