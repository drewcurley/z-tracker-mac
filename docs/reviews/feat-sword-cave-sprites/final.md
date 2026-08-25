# Review: feat/sword-cave-sprites — final (T-213)

**Status:** PASS — sword-cave markers use the real game sprites, and this is the first
Developer ID-signed + **notarized** release. Ships as **v1.1.1**.

unanimous-consensus: T-213

## What shipped
- `swordCaveBadge` draws the real Wooden / White / Magical Sword sprites (via
  `GameSprite.itemFile`) filling the tile with a drop-shadow — no dark plate — matching the
  shop/interior treatment. Atlas-glyph fallback retained.
- **Notarization live:** Developer ID Application cert (Team `VB8Y4UKJPQ`) created via CSR + web
  portal, imported with the G2 intermediate; `notarytool` profile stored. Release DMGs are signed
  (hardened runtime + entitlements), notarized, and stapled.

## Sign-offs
- [x] Analyst — sword sprites were the explicit remaining ask; notarization was the queued item.
- [x] Architect — signing chain verified (`Developer ID Application → Developer ID CA → Apple Root`,
      hardened runtime, secure timestamp); Sparkle framework + helpers re-signed with the same
      identity under runtime; entitlements limited to `device.audio-input` (mic).
- [x] Frontend/UX — sword caves read clearly at map scale; user QA "look good".
- [x] SDET — **750 tests pass** (view-only sprite change; no logic touched).
- [x] DevOps — headless codesign confirmed prompt-free (key-partition-list set); notarize + staple
      via `make-dmg.sh`; dual-arch DMGs + appcasts; v1.0.0+ auto-updates via Sparkle.
- [x] Review Coordinator — T-213 filed; INDEX updated; VERSION → 1.1.1.

## Items to address (follow-ups)
- None. App Store distribution intentionally not pursued (sandboxing + IP-review risk); Developer
  ID / notarized is the chosen channel.
