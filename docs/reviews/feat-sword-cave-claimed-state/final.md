# Review: feat/sword-cave-claimed-state — final (T-065)

**Status:** PASS

unanimous-consensus: T-065

## Summary
Sword-cave tiles now support the claimed (used) state. `isUsedToggleable`
includes `.swordCave`, so all the existing claim machinery applies: marking one
defaults to claimed (T-056), left-click toggles claimed ⇄ located (T-054), a
claimed cave dims on the map, and `SpotSummary` now reads each sword cave's used
state (`usedAny(.swordCave(n))`) instead of the hardcoded `false`, so a placed
sword cave reads "found, not collected" until claimed.

## Sign-offs
- [x] Analyst — closes the gap the user flagged ("these new icons need claimed
      states"): the restyled sword tiles (T-063) now behave like the other
      claimable tiles. The multi-use tiles (door repair / money game / potion)
      are counters, not single-claim, and are intentionally out of scope.
- [x] Architect — no security surface; a domain-flag + summary change.
- [x] Data Engineer — sword caves have distinct raw indices (13/14/15), each a
      valid `extraData` key, so the per-tile used flag stores without collision.
- [x] Backend — reuses `isUsed`/`toggleUsed`/`setUsed`; no new paths. Reverses
      the earlier "drop the sword cave" note deliberately, per user request.
- [x] Frontend — the existing used-dim overlay renders over the sword plate; no
      view change needed. Left-click toggle already routes through
      `isUsedToggleable`.
- [x] UX — a located-but-uncollected sword cave now reads distinctly from a
      collected one, matching secrets/armos/letter. Default-claimed-on-mark is
      consistent with T-056; the user can request a different default.
- [x] Test Engineer — added the toggleable assertions + a Spot Summary test
      (placed→not-done, used→done). 307/307 pass, build clean.
- [x] DevOps — no infra/deps.
- [x] Review Coordinator — task filed (T-065); INDEX regenerated.

## Regression safety
- Additive to `isUsedToggleable`; `.secret(.unknown)` still excluded, all other
  marks unchanged. `SpotSummary` change is confined to the sword-cave `used`
  field. Full suite 307/307 (306 + 1 new), build clean.
- On-device: mark → dimmed, left-click → bright, left-click → dimmed again.
