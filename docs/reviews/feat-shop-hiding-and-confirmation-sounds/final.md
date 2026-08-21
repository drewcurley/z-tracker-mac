# Review: feat/shop-hiding-and-confirmation-sounds — final (T-207 + T-208)

**Status:** PASS — the two buildable items from the T-206 settings audit (animate tile changes,
confirmation sounds), plus the overworld shop-hiding refinements and settings-persistence fixes
the user surfaced during QA. Ships as v0.9.0.

unanimous-consensus: T-207
unanimous-consensus: T-208

## What shipped

### T-207 — animate tiles, shop hiding, persistence, hint hover
- **Animate tile changes:** glyphs pop with a slight overshoot on change; "gettable/open/money"
  highlights pulse — via a `TimelineView(.periodic)` clock, not a global `repeatForever`
  transaction (which had leaked into every tile and flickered the darkening overlays).
- **Shop per-item hiding:** owned items drop from a combo shop; a fully-owned shop takes the full
  "don't care" darkening (+ hover reveal); bomb/meat/shield stay (consumable); book hides on
  `haveBook` incl. the boomstick book.
- **Immediate settings persistence:** every persisted bool writes on `didSet`, not only at
  quest start.
- **Auto-save and quit** (`autoSaveOnQuit`): skips the save prompt (also unblocks the dev scripts).
- **Hint-zone hover label:** the location-hint popover header tracks the hovered zone.

### T-208 — confirmation sounds
- **Voice** (`confirm_speech.wav`, on) and **input** (`reminder_clink.wav`, off) channels — the
  original Windows Z-Tracker sound files. Keyboard covers every region (nav excluded); mouse
  covers overworld + dungeon-room edits.
- **Per-sound volume** sliders (0…100), applied to `NSSound.volume`, persisted immediately.
- Loaded via the Sequoia-safe `AppResources` path loader; warmed up at launch.

## Sign-offs
- [x] Analyst — every change traces to an explicit user request/decision this session; scope is
      the T-206 forward-plan plus the QA-surfaced shop/persistence fixes.
- [x] Architect — no global animation transaction (pulse is a pure time function); sounds/volumes
      persist under their own settings keys; resources load via the direct-path loader (no
      `Bundle.module`, so the Sequoia crash path stays dead); `haveBook` mirrors the reminder
      engine's `hasTheBook`.
- [x] Data Engineer — n/a (no schema/query changes).
- [x] Backend — voice/keyboard/mouse hooks sit at single dispatch/gesture funnels; no double-tick
      (voice and input paths are disjoint).
- [x] Frontend — per-item shop render filters cleanly; darkening overlay is non-hit-testing so it
      never eats the hover reveal; sliders disable with their toggle.
- [x] UX — voice cue confirms an unseeable action; input tick is opt-in; each channel has its own
      volume; the original sounds keep parity with the Windows app.
- [x] SDET — per-item/whole-tile/consumable/book hiding, immediate persistence, volume
      round-trip, options defaults. **739 tests pass.**
- [x] DevOps — clean `swift build` + `swift test`; dual-arch DMGs cut for v0.9.0; `autoSaveOnQuit`
      removes the build-script hang on the save dialog.
- [x] Review Coordinator — tasks T-207 + T-208 filed; INDEX updated; VERSION → 0.9.0.

## Items to address (follow-ups)
- Input tick currently covers mouse on the overworld + dungeon-room surfaces (item-box/blocker
  mouse clicks rely on their keyboard equivalents) — extend to those gesture funnels if desired.
