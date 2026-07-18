# Review: feat/voice-progression-toggles — final (T-142)

**Status:** PASS — voice progression toggles with action-word disambiguation and the
user's overworld/global scoping; the three item-boxes deferred to T-143.

unanimous-consensus: T-142

## Sign-offs
- [x] Analyst — implements the user's two explicit rules (scope; action-word
      disambiguation) verbatim; item-boxes scoped out to T-143.
- [x] Architect — action word is a grammar constant (like NATO letters); item phrases
      stay editable in the config. Region-scope + id→toggle live in a pure helper shared
      by voice and tests.
- [x] Data — sets `PlayerProgressAndTakeAnyHearts` flags via the same `ItemToggle`
      keypaths the click path uses; set-true (directional) so a double-recognition can't
      un-mark.
- [x] Backend — progression parsed before region/structural; requires an action word +
      a `.progression` match, so "take any potion" and bare "meat" aren't swallowed.
- [x] Frontend / UX — editor surfaces the new "Items — acquired" category automatically
      (iterates `categoryOrder`).
- [x] SDET — grammar tests (toggle fires, bare word stays a mark, take-any not swallowed,
      global-vs-overworld) + `ProgressionVoiceApply` tests (region gate, global, directional,
      unknown id, **every catalog id maps**): **579 tests pass**.
- [x] DevOps — no infra change; `swift build` clean.
- [x] Review Coordinator — task filed (T-142); INDEX updated.

## Items to address (T-143+)
- Item boxes (coast / armos / white-sword) need an item vocabulary + "which box + item"
  grammar ("coast ladder").
- A voice "un-mark / clear <item>" verb (progression is currently set-only).
- Remove `/tmp` voice diagnostics before "final" (kept for QA).
