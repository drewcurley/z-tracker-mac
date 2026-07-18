# Review: feat/voice-shop-second-item — final (T-141)

**Status:** PASS — a scoped bug fix; the second shop word now sets the tile's second
item instead of overwriting the primary.

unanimous-consensus: T-141

## Sign-offs
- [x] Analyst — fixes the exact reported behavior ("second item commands overwrite");
      items-region voice deliberately deferred to T-142 (design decision needed).
- [x] Architect — decision logic extracted to a pure `OverworldMark` static so voice and
      tests share one path; no shared click-path mechanics changed.
- [x] Data — reuses the existing `setShopSecondItem` / `shopSecondItem` T-060 slot; no
      duplicate primary/secondary (guarded by `new != first`).
- [x] Backend — additive only when the tile is already a shop of a different kind.
- [x] Frontend / UX — no UI change; voice-only behavior.
- [x] SDET — two new unit tests (sets second item; ignored for empty/same/non-shop):
      **570 tests pass**.
- [x] DevOps — no infra change; `swift build` clean.
- [x] Review Coordinator — task filed (T-141); INDEX updated.

## Items to address (T-142+)
- Items-region voice: progression toggles + coast/armos/white-sword item boxes — pending
  the user's design call (global vs region scope; word collisions; item vocabulary).
- Remove `/tmp` voice diagnostics before "final" (kept for now to aid QA).
- Dungeon-number dedup (voice can place a level twice) — verify reference behavior first.
- Dungeon room-chooser `.popover` ViewBridge crash (macOS 27 beta) — separate task.
