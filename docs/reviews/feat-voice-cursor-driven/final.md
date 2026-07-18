# Review: feat/voice-cursor-driven — final (T-138)

**Status:** PASS WITH ITEMS — voice is now cursor-driven & region-aware; remaining
vocabulary + the voice editor tracked in T-139.

unanimous-consensus: T-138

## Sign-offs
- [x] Analyst — scope is the cursor-driven grammar + contextual navigation the user
      asked for; per-region action vocab and the editor are deferred to T-139.
- [x] Architect — voice reuses the same cursor/region state (`TrackerFocusState`) and
      region-apply code the hotkeys use; grammar stays pure/testable, execution is the
      thin region-aware layer.
- [x] Data — `RoomType.isEntrance` + overworld dungeon-marker/entrance scans read model
      state; no schema change.
- [x] Backend — parse maps phrases to a small cursor-oriented command set; `set`/`enter`
      verb disambiguates mark-vs-switch.
- [x] Frontend / UX — coord moves the ring; action marks at the ring; contextual
      start/restart & dungeon enter/exit match run flow; NATO letters + no compass words.
- [x] SDET — grammar fully unit-tested (coord/action/NATO/nav/set-vs-enter/take-any):
      **557 tests pass**. AVFoundation path user-QA'd live.
- [x] DevOps — no infra change; `.app` via `build-app.sh` (stable-signed).
- [x] Review Coordinator — task filed (T-138); INDEX updated; follow-ups in T-139.

## Regression safety
- Additive to voice; the shared overworld apply is unchanged. Non-overworld regions get
  cursor movement but action words safely no-op (logged) until their vocab lands.

## Items to address (T-139)
- Voice command **editor** (data-driven grammar: `VoiceCatalog` + `VoiceConfig` +
  editor UI, mirroring hotkeys). Dungeon-room/blocker/item action words; progression
  toggles; shop second item; remove `/tmp` diagnostics.
