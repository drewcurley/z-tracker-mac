# Review: feat/door-inference-default-on — final (T-156)
**Status:** PASS — door inference on by default; the "doesn't work in voice" report was a default-off setting.
unanimous-consensus: T-156
## Sign-offs
- [x] Analyst — root cause (setting default off) confirmed by test, not guessed; movement-inference deferred with rationale.
- [x] Architect — one-line default flip; existing persisted values respected.
- [x] Data — persistence tests updated to a still-default-false option for the "uncommitted" case.
- [x] Backend — no logic change; the apply path already infers when enabled.
- [x] Frontend/UX — Settings toggle unchanged; helpful default.
- [x] SDET — default assertion flipped; 2 diagnostic tests added: **605 tests pass**.
- [x] DevOps — no infra; build clean.
- [x] Review Coordinator — T-156 filed; INDEX updated.
