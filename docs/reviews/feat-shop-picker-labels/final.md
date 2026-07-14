# Review: feat/shop-picker-labels — final (T-061)

**Status:** PASS — trivial label change.

unanimous-consensus: T-061

## Sign-offs
- [x] Analyst — drop the redundant "shop" from the picker; submenu is already
      titled "Shop". In scope.
- [x] Frontend — `ShopKind.shortName` used in both shop submenus; `displayName`
      kept for accessibility/tooltips.
- [x] Test Engineer — pure label change; 305/305 unchanged, build clean.
- [x] UX / Data / Backend / Architect / DevOps — N/A.
- [x] Review Coordinator — task filed (T-061); INDEX updated.

## Regression safety
- String-only change. Full suite 305/305, build clean.
