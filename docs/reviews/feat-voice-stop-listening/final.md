# Review: feat/voice-stop-listening — final (T-155)
**Status:** PASS — voice can now be stopped hands-free; resume via mic icon/hotkey.
unanimous-consensus: T-155
## Sign-offs
- [x] Analyst — closes the "on but not off" gap; resume is the existing mic toggle.
- [x] Architect — Nav_StopVoice → stopListening → controller stop(); reuses existing stop path.
- [x] Backend — no bare "stop" (collision-safe); "restart" still go-to-start.
- [x] Frontend/UX — editable phrases; mic icon reflects stopped state.
- [x] SDET — stop-listening + restart-guard grammar tests: **603 tests pass**.
- [x] DevOps — no infra; build clean.
- [x] Review Coordinator — T-155 filed; INDEX updated.
