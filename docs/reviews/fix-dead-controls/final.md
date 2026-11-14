# Review: fix/dead-controls — final (T-249)

**Status:** PASS (T-247 + T-249) — single-operator review (audit §4 follow-up; user-directed scope).

unanimous-consensus: T-249
unanimous-consensus: T-247

## Sign-offs
- [x] Analyst — each audit item wired to its reference behavior; click keys keep the user's no-emulation decision.
- [x] Architect — no Accessibility/TCC need — no synthesized events.
- [x] Data — n/a for this change.
- [x] Backend — shared helpers (DungeonRoomMark.leftClick / nudgeDoor) so mouse and keys run one path.
- [x] Frontend / UX — take-any/take-this choices shown in a toast as the pie-menu stand-in; mirror window never opens a picker.
- [x] SDET — 11 new tests + quit-warning rule; 847 pass.
- [x] DevOps — no pipeline change.
- [x] Review Coordinator — T-247 + T-249 filed; INDEX + CHANGELOG + reference-coverage updated.
