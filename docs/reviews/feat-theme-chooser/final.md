# Review: feat/theme-chooser — final (T-187)

**Status:** PASS WITH ITEMS — the theme chooser + infrastructure work and are approved
("the theme chooser works"). Light-mode visual polish is a tracked follow-up (T-188).

unanimous-consensus: T-187

## What shipped
- `AppTheme` (dark default / light / system) in TrackerCore, own persistence key.
- Removed the dead "Dungeon 'sunglasses'" toggle (one of the settings-audit dead toggles).
- Theme picker in Settings → Other; `AppThemeController` sets `NSApp.appearance` app-wide,
  applied on launch + change.

## Sign-offs
- [x] Analyst — replaces a dead toggle with a working feature; light-mode polish scoped
      out to T-188 (explicit, not silent).
- [x] Architect — `NSApp.appearance` is the standard app-wide appearance hook; theme is a
      persisted enum, additive.
- [x] Data — enum persists under its own key (round-trip tested); default `.dark`.
- [x] Backend — n/a beyond the option; controller is a thin AppKit call.
- [x] Frontend / UX — picker live-updates all windows; **known items:** Light mode themes
      only the chrome (dark board + hardcoded dark boxes remain), with contrast/aesthetic
      issues → T-188.
- [x] SDET — default + persistence covered. **721 tests pass.**
- [x] DevOps — no infra change; clean build/test; `.app` rebuilt.
- [x] Review Coordinator — task filed (T-187); INDEX updated; follow-up T-188 noted.

## Items to address (follow-ups)
- **T-188** — Light theme design-system pass: replace hardcoded dark colors
  (`Color(white:)`, `.black` fills, white text) with adaptive semantic tokens; decide how
  the sprite/content boxes render in light mode; meet WCAG contrast.
