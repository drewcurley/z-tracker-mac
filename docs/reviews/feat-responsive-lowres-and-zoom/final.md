# Review: feat/responsive-lowres-and-zoom — final (T-228, T-229)

**Status:** PASS — a responsive low-resolution layout (auto map-scale, collapsible Flags/Info,
compact buttons) plus a complementary browser-style universal UI zoom. Both target the single-1080p
"game + tracker on one screen" case. User QA'd and approved. Ships as notarized **v1.2.7**.

unanimous-consensus: T-228
unanimous-consensus: T-229

## What shipped
- **T-228** — dungeon map auto-scales 100/80/60% at > 975 / ≤ 975 / ≤ 850; Flags/Info auto-collapse
  to slim tap-to-expand chips (Info ≤ 1035, Flags ≤ 900) instead of wrapping below the trackers; a
  new "Show Flags panel" setting mirroring "Show Info panel"; tracker buttons shrink 34 → 30px and
  Blockers boxes 30 → 26px below 1100 wide.
- **T-229** — a "Tracker zoom" setting (100/90/80/70/60%) that scales the whole tracker. Browser-style:
  zooming out lays out at the enlarged logical width then scales down, so it frees horizontal room
  too and composes with the T-228 breakpoints. Inert at 100%; never applied to the mirror window.

## Sign-offs
- [x] Analyst — matches the request set exactly (auto map-scale, Show-Flags setting, per-panel
      collapse thresholds, compact buttons + blockers, then the complementary zoom). The remaining
      1080p vertical overflow is out of scope by the user's own call (timeline is FYI).
- [x] Architect — no model changes beyond one persisted bool (`showFlagsPanel`) and one display pref
      (`@AppStorage "ui.zoom"`); no security surface, no data leaves the app; mirror path explicitly
      excluded so streaming output is unchanged.
- [x] Data — n/a (no schema/query changes; `showFlagsPanel` round-trips with the existing bool set).
- [x] Backend — breakpoints derive from a single viewport measurement; the env is a Bool so each view
      keeps its own baseline; zoom reuses `ScaledFootprint` rather than a parallel mechanism.
- [x] Frontend/UX — collapse chips are slim and clearly toggle; the zoom picker sits with the other
      display prefs on both the welcome and in-app settings; the soften-at-non-round-scale trade-off
      was surfaced before building and accepted.
- [x] SDET — pure-layout/SwiftUI feature; the core (`TrackerOptions.showFlagsPanel` persistence) is
      covered by the existing options round-trip suite. **789 tests pass.**
- [x] DevOps — clean build/test; ships as notarized dual-arch DMGs + appcasts for v1.2.7.
- [x] Review Coordinator — T-228 + T-229 filed; INDEX + CHANGELOG (1.2.7) updated; VERSION → 1.2.7.

## Items addressed during QA
- Chips didn't appear at first — root-caused to measuring content (min) width instead of the
  viewport; reader moved to the ScrollView. Fixed.
- Collapse fired too late / shared threshold — split to Info ≤ 1035, Flags ≤ 900. Fixed.
- Blockers weren't shrinking, and the 60% band was missing — both added. Fixed.
- Zoom + widen left the canvas cropped (vertical ScrollView shrank to the fixed-width zoomed content,
  freezing the viewport reader) — ScrollView forced to fill the window. Fixed.

## Items to address (follow-ups)
- Optional: a keyboard shortcut / pinch gesture for zoom — deferred; the picker is the v1 control.
