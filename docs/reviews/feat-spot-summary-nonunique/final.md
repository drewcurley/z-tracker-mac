# Review: feat/spot-summary-nonunique — final (T-076)

**Status:** PASS — Spot Summary now shows the Non-Unique Locations counts.

unanimous-consensus: T-076

## Sign-offs
- [x] Analyst — scope: add the missing Non-Unique section per user feedback. Shops
      out of scope (unbounded in the reference) — flagged for a follow-up call.
- [x] Data — totals transcribe the reference `maxUses` (`TrackerModel.fs:290-298`),
      1Q vs 2Q; `remaining = total − marked`. Marks already distinguish each type.
- [x] UX — number + name + icon row (bright = remaining) matches the Secrets
      section; popover widened 300→340 to fit up to 10 icons.
- [x] SDET — 1 test (per-quest totals + remaining after marking); 421 total pass;
      clean debug + release. On-device: popover shows Door 9 / MMG 5 / Hint 4 /
      Take-any 4 / Potion 7 on empty 1Q.
- [x] Architect / Backend / DevOps — N/A.
- [x] Review Coordinator — task filed (T-076); INDEX updated.

## Regression safety
- Additive: a new `nonUniques` field (one call site) + a new view section. Existing
  unique/secret sections unchanged. Build clean; 421 pass.

## Follow-up
- Shops (bomb/candle/ring/meat): reference has no fixed total (max 999). Decide
  with the user whether to show a marked-count (no "remaining") for shop kinds.
