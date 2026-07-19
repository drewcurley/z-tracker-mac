# Review: feat/voice-item-boxes — final (T-143)

**Status:** PASS — the three item boxes are voice-settable via the user's "box + item"
grammar; the coast≠ladder rule and overworld scoping are honored.

unanimous-consensus: T-143

## Sign-offs
- [x] Analyst — implements the user's chosen "box + item" grammar; the un-mark verb and
      dungeon-item-card reuse are scoped out.
- [x] Architect — box-phrase strip resolves the "white sword" triple-collision (box
      qualifier / item / cave). Item ids match the hotkey suffixes so `ItemBoxMark` is
      reused verbatim; a pure `ItemBoxVoiceApply` is shared by voice and tests.
- [x] Data — placement goes through `ItemBoxMark.apply` → `canSelectItem`, so the
      unique-item rule and the deliberate coast≠ladder rule both apply; "nothing" clears.
- [x] Backend — parsed before region-first so the overworld cave mark can't grab
      "white sword item …"; requires both a box name and a following item.
- [x] Frontend / UX — editor surfaces the two new categories automatically.
- [x] SDET — grammar tests (box+item, white-sword self-name strip, bare word stays a
      mark, clear) + helper tests (region gate, unknown ids, coast≠ladder, **every box &
      item id maps**): **588 tests pass**.
- [x] DevOps — no infra change; `swift build` clean.
- [x] Review Coordinator — task filed (T-143); INDEX updated.

## Items to address (later)
- Voice "un-mark / clear <item>" verb for progression toggles.
- Reuse `.items` for the per-dungeon item card (`.dungeonItem` region).
- Remove `/tmp` voice diagnostics before "final" (kept for QA).
