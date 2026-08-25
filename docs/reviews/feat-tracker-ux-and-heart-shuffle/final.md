# Review: feat/tracker-ux-and-heart-shuffle — final (T-212)

**Status:** PASS — five live-play items, each QA'd with the user. Ships as **v1.1.0** (auto-updates
in place for v1.0.0 users via Sparkle — the first production exercise of the updater).

unanimous-consensus: T-212

## What shipped
1. **Sword-cave hint auto-fill** — marking a White/Magical-Sword cave fills its "UN" hint to the
   screen's zone (mouse/hotkey/voice), mirroring dungeon placement.
2. **Bigger indicators** — hint chips 9→12pt, triforce pips 9→15pt.
3. **Shop redraw** — no orange plate; sprites fill the tile with a drop-shadow; fixes map + chooser
   in one change.
4. **Large-X on unwanted items** — big dimmed X by default (`.skipped` now reads untaken, not
   bright); a persisted setting reverts to the corner X.
5. **Heart Shuffle 3-state (off/intra/full) + intra deduction** — enum with back-compat decode;
   intra deduces the heart into the last open slot of the pinned floor/basement category.

## Sign-offs
- [x] Analyst — every item traces to explicit user feedback; intra mechanic confirmed against the
      randomizer option, not invented.
- [x] Architect — `HeartShuffle` migration keeps saves loading (Bool→enum custom `Codable`); the
      deduction is a pure re-derivation over box state (idempotent, converges), only ever *adds* a
      deduced heart; the sword-cave hint reuses the existing zone-hint path; no new global state.
- [x] Data — save round-trip verified; the one behavioral consumer (`applyFloorItemHearts`) and the
      spoiler fill both map cleanly to the enum.
- [x] Backend — sword-cave closure threaded through all three apply paths; deduction triggered from
      one reactive `.onChange` + `restore`.
- [x] Frontend — shop change is view-local (map + chooser share it); largeUnwantedX rides in
      `ItemIconOptions`; 3-way Flags tile with an I/F badge + mid-run confirm.
- [x] UX — indicators legible; shops read clearly without the plate; skipped items read as untaken;
      intra auto-heart matches the player's floor/basement mental model.
- [x] SDET — `HeartShuffleTests` (codec, cycle, pre-placement, degenerate + D8/SQ-L4 + FQ-L1
      category deduction), sword-cave hint tests, option default; Bool→enum migration across suites.
      **750 tests pass.**
- [x] DevOps — clean build/test; dual-arch DMGs + appcasts for v1.1.0.
- [x] Review Coordinator — T-212 filed; INDEX updated; VERSION → 1.1.0.

## Items to address (follow-ups)
- Notarization once the user's (pending) Apple Developer enrollment activates — a drop-in that
  removes the first-launch Gatekeeper prompt; unrelated to the auto-update flow.
- Intra deduction only *adds* a deduced heart (won't retract if a prior box is un-identified) — by
  design; revisit if it proves confusing in play.
