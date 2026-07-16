# Review: feat/recorder-destination-toggles — final (T-093)

**Status:** PASS — recorder new/unbeaten toggles restored by the widget.

unanimous-consensus: T-093

## Sign-offs
- [x] Analyst — completes the agreed mid-game-settings design (the user chose "by
      the recorder widget," not the Flags section).
- [x] Frontend — an `ellipsis.circle` button + popover on `RecorderInfoWidget`
      bound to the existing `recorderTo*` model settings.
- [x] UX — mirrors the reference's '...' next to Recorder Destination.
- [x] SDET — build clean; 450 tests unaffected (the `RecorderDestinations` logic
      these toggles feed is already covered). No new logic to test.
- [x] Architect / Data / Backend / DevOps — N/A.
- [x] Review Coordinator — task filed (T-093); INDEX updated.

## Regression safety
- Additive UI over existing settings; the destination computation is unchanged.
