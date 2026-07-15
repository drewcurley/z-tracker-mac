# Review: feat/wire-shops-before-dungeons — final (T-004.2)

**Status:** PASS — "Shops before dungeons" now reorders the overworld tile popup.

unanimous-consensus: T-004.2

## Sign-offs
- [x] Analyst — scope: wire the previously-dead `shopsBeforeDungeons` option so
      the tile popup starts with shops (on) or dungeons (off), per the reference
      `Overworld.ShopsFirst`. In scope; persistence explicitly deferred.
- [x] Frontend — extracted the Shop submenu (+ conditional "2nd item") into
      `shopMenus`; `markMenu` emits it before Dungeon when the flag is set, else
      in its original slot. Reads the existing `options` property already on the
      view — no new plumbing.
- [x] UX — matches the reference wording/behavior; default `true` (shops first)
      matches the reference's live default, so out-of-the-box order is faithful.
- [x] Backend — pure view reordering; the mark-applying actions are unchanged.
- [x] SDET — SwiftUI menu order isn't unit-testable headlessly; verified on-
      device: with the default (on), the popup lists Shop above Dungeon. The off
      branch (`if !shopsBeforeDungeons`) reproduces the exact prior order. Full
      suite 335/335, build clean debug + release.
- [x] Data / Architect / DevOps — N/A.
- [x] Review Coordinator — task filed (T-004.2); INDEX updated.

## Regression safety
- View-only: the same submenus, the same actions, only their order changes
  behind a boolean. When off, the popup is byte-for-byte the previous order.
  Build clean debug + release, 335/335.
