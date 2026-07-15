# Review: feat/wire-more-settings-hiding — final (T-004.3)

**Status:** PASS — the 12 "More settings" tile-kind hides now dim marked tiles (hover / rescue reveal).

unanimous-consensus: T-004.3

## Sign-offs
- [x] Analyst — scope: wire the 12 previously-dead tile-kind checkboxes so a
      marked tile of a checked kind is hidden (dimmed) on the map. The two shop
      checkboxes are explicitly deferred to T-004.4 (shop-rendering change). In
      scope.
- [x] Data — `hideableKind` mirrors `AsTrackerModelOptionsOverworldTilesToHide`
      exactly (sword1-3, large/medium/small secret, door repair, money game, the
      letter, armos, hint shop, take-any); unknown-secret / shops / dungeons /
      any-road / potion-shop → nil. `isKindHidden` reads the existing
      `hiddenOverworldTiles` dict; no schema change.
- [x] Frontend — `TileView` wraps its mark layers in a `Group` and applies
      `.opacity(kindHidden && !revealHovered ? 0.28 : 1)` + `.onHover`.
      `OverworldMapView` computes `kindHidden` per tile and takes
      `hasRescuedZelda` (threaded from the model). No change to non-hidden tiles.
- [x] UX — dimming matches the reference's dark-X (map stays uncluttered);
      hover peeks the tile; rescuing Zelda reveals everything. 0.28 opacity reads
      as "present but muted" without vanishing.
- [x] Backend — the hide policy is a pure function in TrackerCore; the view is
      the only consumer. Placing/clearing marks is unchanged.
- [x] SDET — `OverworldTileHidingTests`: the 12-kind mapping, nil for
      non-hideable, checked-only, and rescue-reveal. 339/339. On-device A/B:
      an Armos tile (kind checked) rendered dimmed; the same tile switched to
      Money Making Game (not checked) rendered bright — proving the
      kindHidden→opacity path end-to-end. Build clean debug + release.
- [x] Architect / DevOps — N/A.
- [x] Review Coordinator — task filed (T-004.3); INDEX updated.

## Regression safety
- Additive: a new TrackerCore file + one wrapped Group / two new view inputs.
  `kindHidden` defaults false, so tiles of unchecked kinds are byte-for-byte
  unchanged. Build clean debug + release, 339/339.

## Note
- Hover-reveal uses SwiftUI `.onHover` (tracking-area based); it works with real
  pointer movement but couldn't be captured via a synthetic cursor warp (warps
  don't emit mouse-tracking events). The dim/bright A/B confirms the core wiring.
- Shop hiding (T-004.4) intentionally deferred, not silently dropped.
