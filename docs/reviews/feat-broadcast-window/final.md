# Review: feat/broadcast-window — final (T-178)
**Status:** PASS — mirror window + per-window breakout + info/icon settings; user QA'd.
unanimous-consensus: T-178

## Sign-offs
- [x] Analyst — re-scoped per [[broadcast-window-rethink]]; the reference's fixed-layout
      broadcast mode was deliberately not cloned. Old broadcast options removed, not left dead.
- [x] Architect — the mirror reuses the shared @Observable state (no sync layer); app-global
      singletons (dispatcher/voice/poll) stay single-instance via `isMirror`. No new I/O.
- [x] Data Engineer — added `showInfoPanel` + `useDetailedAppIcon` (persisted bools); removed
      the broadcast options + their bespoke enum persistence; tests updated.
- [x] Backend Engineer — per-window breakout: pop-out controls set their own parent's flag;
      the shared window resets both on close. Documented edge (close-brings-back-both).
- [x] Frontend Engineer — mirror titled "Broadcast" so the primary key monitor skips it;
      icon rounding baked at build time (`make-simple-icon.swift`), not per-launch.
- [x] UX Designer — simple icon is the reliable default (open/closed); detailed is an
      opt-in running override — chosen after the persistent-custom-icon caveat was surfaced.
- [x] SDET — 686 tests. Option defaults/persistence updated; the broadcast-enum test removed
      with the enum. Window/mirror wiring is UI-state, exercised by user QA.
- [x] DevOps — build-app.sh builds the .icns from the simple icon + copies the detailed one;
      no infra change.
- [x] Review Coordinator — T-178 filed; INDEX updated.
