# Review: feat/custom-waypoint — final (T-162)
**Status:** PASS — a second freely-placeable overworld marker, mirroring the start spot.
unanimous-consensus: T-162
## Sign-offs
- [x] Analyst — closes audit #13; scope held to a marker (no routing/persistence); also corrected 3 stale audit lines (#13/#14/#18).
- [x] Architect — one model field + view props + wiring; no new state machinery; mirrors the proven start-spot pattern.
- [x] Data — single optional coordinate; no schema/query surface.
- [x] Backend — pure marker; no side effects on marks, take-any, or routing.
- [x] Frontend — amber diamond distinct from the violet start-spot ring and cyan cursor; decorative overlay (allowsHitTesting false); Set/Clear in the tile menu.
- [x] UX — behaves like the start spot users already know; independent second bookmark.
- [x] SDET — model test: set/clear + independence from start spot; **622 tests pass**.
- [x] DevOps — no infra; build clean.
- [x] Review Coordinator — T-162 filed; INDEX + coverage audit updated.
