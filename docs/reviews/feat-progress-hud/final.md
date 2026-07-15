# Review: feat/progress-hud — final (T-035.10)

**Status:** PASS

unanimous-consensus: T-035.10

## Summary
The reference's faux items+hearts inventory HUD, in a detachable window. Replaces
the T-035.9 Item Progress strip and the "Max Hearts" field. `FauxItemsHUD`
composites by drawing into a CGContext (erase unowned slots, overlay downgraded
variants, draw the heart row); the "Progress" overlay-row icon toggles a separate
resizable `WindowGroup`. Adds a meat toggle (`hasMeat`) driving the HUD's meat
slot.

## Sign-offs
- [x] Analyst — the user's redesign: mimic the in-game HUD for familiarity, one
      detachable window (hover preview dropped), letter keyed to the letter cave
      being used, meat tracked. Supersedes T-035.9 (removed).
- [x] Architect — new secondary window; no security surface. Assets attributed
      in NOTICE.md (MIT).
- [x] Data Engineer — `hasMeat` added to `PlayerProgressAndTakeAnyHearts` (+
      reset); `havePotionLetter` left untouched (HUD uses the letter-used signal).
- [x] Backend — HUD is a pure compositor over player state; the window is opened
      by a model flag via `openWindow`/`dismissWindow`.
- [x] Frontend — CGContext-draw compositing (no manual pixel flipping, which had
      caused an upside-down HUD); window default 2×, resizable, nearest-neighbor
      stretch; plain click toggle (a popover fought the click).
- [x] UX — familiar inventory layout; hearts fill logically (first three red top
      row, spill to the second); Max Hearts removed as redundant with the in-game
      HUD.
- [x] Test Engineer — compositor tests (empty + fully-kitted render to a 98×79
      image); the meat grid slot + toggle covered by the updated grid tests.
      326/326 pass, build clean. HUD verified by direct PNG dump + on-device.
- [x] DevOps — three PNGs added to `Package.swift` resources + NOTICE.md.
- [x] Review Coordinator — task filed (T-035.10; supersedes T-035.9); INDEX
      regenerated.

## Seven lenses (feature)
- **Product/Marketing:** a familiar, streamer-friendly detachable HUD strengthens
  the "faithful clone" story; built from our own atlases + the reference HUD art.
- **Developer:** the compositor is pure and testable; the pixel-flip trap was
  sidestepped by drawing rather than copying.
- Others N/A for a solo tracker.

## Regression safety
- Removes the T-035.9 strip and Max Hearts (both intentional). The new window
  doesn't open at launch (secondary WindowGroup). Full suite 326/326, build
  clean. On-device with the user: click toggles the window, HUD renders correctly
  and resizes, letter lights when the cave is used.
