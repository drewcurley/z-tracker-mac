# Review: feat/settings-panel-followups — final

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats.

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- [ ] The "More settings…" popover's default SwiftUI placement occasionally
      anchors slightly off the left edge of the window at smaller sizes
      (cosmetic, not functional — confirmed by screenshot). Worth an explicit
      `attachmentAnchor`/`arrowEdge` pass during a later UI-polish task.

## Suggestions (consider for polish)
- None beyond the above.

## Agent Sign-offs
- [x] Analyst — every T-005 acceptance criterion resolved for real (no items
      re-deferred); scope didn't creep into unrelated settings-panel work.
- [x] Architect — no security-relevant surface; `AVSpeechSynthesizer`/
      `AVSpeechSynthesisVoice` are local, no network/permission surface
      beyond what speech synthesis (not recognition) already implies.
- [x] Data Engineer — `OverworldHiddenTileKind`'s 12 cases and the 2
      shop-hiding fields verified field-for-field against
      `TrackerModelOptions.OverworldTilesToHide` (14 total, confirmed by count).
- [x] Backend — N/A (no server); model stays UI-agnostic.
- [x] Frontend — built, ran, and visually confirmed the "More settings…"
      popover renders all 14 items correctly via screenshot.
- [x] UX — tooltips/descriptions were available in the reference source
      (`OptionsMenu.fs`) but not all were ported to `.help()` text in this
      pass — acceptable for a functional-parity pass, flagged as a natural
      follow-up if UX polish becomes a priority, not a blocker now.
- [x] Test Engineer — 3 new test functions (parameterized over all 12 tile
      kinds), 21/21 total passing.
- [x] DevOps — no CI/deploy changes.
- [x] Review Coordinator — process followed; `domain.md` fully reconciled
      (§ 4.1 and § 4.9), no remaining "unconfirmed" language for items this
      task set out to resolve.

## Lens Sign-offs (major decisions — none this task; routine follow-up work)
- [x] CEO/Purchasing/Investor/Marketing — N/A.
- [x] PM — a task that closes its own follow-up list cleanly, rather than
      spawning a T-006 for residue, is exactly the shape a "follow-ups" task
      should have.
- [x] Adopter — feature-complete settings panel now matches the reference
      app's actual behavior, including the two popovers.
- [x] Builder — reading the shared `OptionsMenu.fs` component directly (once
      it was found) resolved 5 fields' placement in one pass instead of 5
      separate investigations — a good habit to repeat for the dungeon
      tracker's much larger surface.
