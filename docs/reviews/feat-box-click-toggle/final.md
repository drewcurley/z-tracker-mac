# Review: feat/box-click-toggle — final (T-044)

**Status:** PASS — interaction change, matches the map's model.

unanimous-consensus: T-044

## Sign-offs
- [x] Analyst — scope: make box interaction mirror the overworld map (right =
      picker, left = toggle) for dungeon boxes and the three off-map picker
      boxes. Exactly the user's ask.
- [x] Backend / Data — the toggle is a pure `Box.toggleTaken()` (`.yes`⇄`.no`,
      `.skipped`→`.yes`, no-op when empty) + `hasKnownItem`. Item identity is
      never changed by a toggle.
- [x] Frontend — `BoxView`: `onTapGesture` toggles when `hasKnownItem` else
      opens the picker; `onRightClick` opens the picker. The `RightClickCatcher`
      overlay only claims right-mouse events, so left/right paths stay isolated
      (a right-click doesn't also fire the tap gesture).
- [x] UX — the frequent action (mark a floor item taken) is now a single
      left-click instead of a picker round-trip; consistent with the map. Right-
      click still reaches the full picker to set/change/clear the item.
- [x] Test Engineer — `toggleTaken` test: empty no-op, known untaken→taken→
      untaken round-trip (item preserved), skipped→taken. 283/283 pass.
      On-device: left-click floor heart flips green⇄orange; right-click empty
      and right-click filled both open the picker (filled shows current item).
- [x] Architect / DevOps — N/A; no schema, infra, or security surface.
- [x] Review Coordinator — task filed (T-044); INDEX updated.

## Regression safety
- The picker itself is unchanged (left = have it, right = don't have it). Only
  the box's own two gestures were remapped. Full suite 283/283, build clean
  debug + release.
