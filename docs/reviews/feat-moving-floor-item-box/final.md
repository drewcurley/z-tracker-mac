# Review: feat/moving-floor-item-box — final (T-042)

**Status:** PASS — small, model-backed UI addition.

unanimous-consensus: T-042

## Sign-offs
- [x] Analyst — scope: expose the existing L1↔L4 extra-box move (T-013 model) as
      a clickable "ghost" box, matching the reference. No new mechanics invented.
- [x] Data — the shared `finalBoxOf1Or4` is a single `Box`; `boxes` already
      appends it to the owning dungeon, so the marked item travels with the
      toggle for free. `ghostBoxDungeonId` returns the non-owner of {L1, L4},
      `nil` in HDN (no shared box).
- [x] Frontend — `GhostBoxView` reuses the 34pt cell size so it aligns with the
      real boxes; rendered only in `instance.ghostBoxDungeonId`'s card. Reading
      `isSecondQuestDungeons` in the card body keeps both the owner and ghost in
      the observation graph, so a toggle refreshes both.
- [x] UX — dashed, dimmed slot with a down-arrow reads as "the extra item can
      drop here" — clearer than the reference's inscrutable gray box; tooltip
      spells out the 1Q/2Q meaning.
- [x] Backend — `toggleSecondQuestDungeons()` is a one-line flip; idempotent
      round-trip verified by test.
- [x] Test Engineer — new tests: ghost id + toggle round-trip (item travels),
      and HDN → no ghost. 277/277 pass. On-device: ghost under L4 in 1Q → click
      → extra box under L4 (with stair glyph), ghost under L1.
- [x] Architect / DevOps — N/A; no schema, infra, or security surface.
- [x] Review Coordinator — task filed (T-042); INDEX updated.

## Regression safety
- Additive: the ghost renders only for one dungeon in DEFAULT mode; box lists
  and completion logic are unchanged. Full suite 277/277, build clean
  debug + release.
