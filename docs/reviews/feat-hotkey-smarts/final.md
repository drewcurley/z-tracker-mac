# Review: feat/hotkey-smarts — final (T-169)
**Status:** PASS — per-context smarts + Unmark–Remark chains; user playtest cleared.
unanimous-consensus: T-169

## Sign-offs
- [x] Analyst — scope matches the agreed T-169 (smarts only; cheat sheet is T-170).
- [x] Architect — no new I/O or permissions; pure model mutations.
- [x] Data Engineer — `applyMaybeBlockerLogic` added to the container; no schema change.
- [x] Backend Engineer — the Unmark–Remark `justUnmarked` state lives on the dispatcher,
      scoped by (tab, cell, selector) so a same-coordinate room in another dungeon can't
      false-fire; the reference's "don't clear on fire" is preserved so successive chains
      keep firing.
- [x] Frontend Engineer — item/shop/blocker/room apply reuse the existing enums; the two
      "activate box" chains park the dungeon-item cursor (our keyboard-native stand-in for
      the reference's mouse warp, recorded as a deliberate adaptation).
- [x] UX Designer — the fresh-press-stays-YES choice was put to the user and confirmed,
      rather than silently matching the reference's NO.
- [x] SDET — 681 tests. Covers maybe-blocker promote/add/skip, item cycle + Nothing-key,
      shop add/remove/replace, and the chain state machine (mark→unmark→remark fires,
      single mark doesn't, different key breaks the chain, tab-scoped, monster mappings).
- [x] DevOps — no infra.
- [x] Review Coordinator — T-169 filed; INDEX updated.
