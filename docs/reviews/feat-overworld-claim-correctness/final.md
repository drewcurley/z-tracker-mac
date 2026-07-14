# Review: feat/overworld-claim-correctness — final (T-058)

**Status:** PASS — bug fix + two claimed-state corrections.

unanimous-consensus: T-058

## Sign-offs
- [x] Analyst — scope: the over-placement bug plus the two related claimed-state
      asks (unknown-secret, groundhog). Coherent theme. In scope.
- [x] Data — `OverworldTileLimits.maxUses` transcribes the reference
      `overworldTiles` maxuses column (1 / 4 / quest-dependent / 999). Disable
      test: `otherCount(type) >= max`, excluding the current tile's own mark so
      re-selecting is allowed.
- [x] Frontend — `markMenu` computes a per-mark count once and `.disabled(...)`s
      each option; parameterized submenus (dungeon/any-road/sword) disable
      per-number. `clearAllUsed` keeps marks + non-used extra-data.
- [x] UX — you can no longer mark a 2nd unique or overshoot a capped type; the
      exhausted option greys out. Unknown secrets can't be falsely "collected".
- [x] Backend — groundhog now clears the overworld claimed flags alongside the
      existing progress/take-any reset, matching "replay re-collects".
- [x] Test Engineer — `OverworldClaimCorrectnessTests`: max-use table, unknown
      unclaimable, clearAllUsed keeps marks, groundhog clears used. 304/304.
      On-device: "The letter" disables after one placement.
- [x] Architect / DevOps — N/A.
- [x] Review Coordinator — task filed (T-058); INDEX updated.

## Regression safety
- Additive limits (unbounded types unaffected); the `.secret(.unknown)` change
  only removes an incorrect capability; groundhog gains one clearing call. Full
  suite 304/304, build clean debug + release.
