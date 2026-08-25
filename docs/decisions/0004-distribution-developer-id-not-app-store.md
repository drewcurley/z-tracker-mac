# ADR 0004 — Distribute via Developer ID + notarization (GitHub), not the Mac App Store

**Status:** accepted
**Date:** 2026-08-24
**Deciders:** Drew Curley (solo; single-operator review per `playbook/AGENTS.md` §12)

## Context

By v1.1.1 the app has a complete direct-distribution pipeline: dedicated arm64 +
Intel builds, **Developer ID** code signing, **Apple notarization** + stapling, GitHub
Releases, and **Sparkle** in-place auto-update (per-arch EdDSA-signed appcasts). First
launch is prompt-free; updates are one-click.

The question raised: should we *also* (or instead) ship on the Mac App Store?

## Decision

**No. Distribution stays Developer ID / notarized, delivered via GitHub Releases with
Sparkle auto-update.** The Mac App Store is explicitly declined.

## Rationale

1. **Intellectual-property rejection risk (decisive).** The app ships real ripped
   *Legend of Zelda* assets (overworld tile atlases, item/enemy sprite GIFs) and uses
   the Zelda name. App Review enforces Guideline 5.2 (IP) strictly, and Nintendo is an
   aggressive rights-holder. A fan tool on their sprites is a near-certain rejection —
   and a liability even if it slipped through. Direct notarized distribution sidesteps
   this gate entirely, which is why it's the norm for randomizer-community tools.
2. **Sandbox rework.** MAS mandates the App Sandbox. The app writes app-managed files
   (autosave / `last-session.json` / completed saves / `Notes.txt`) straight to
   `~/Documents/ztracker/`, which a sandboxed app cannot do — it would require moving
   everything into the container and adopting security-scoped bookmarks for user-chosen
   paths. A real refactor of the save/file layer for no user benefit here.
3. **Self-update is disallowed on MAS.** We'd have to rip out the Sparkle pipeline we
   just built (and which the community expects), letting the store own updates.
4. **The audience already uses GitHub.** The Z1R community downloads tools from GitHub
   as a matter of course; notarized DMGs open with no friction. The channel fits the users.

## Consequences

- Releases are cut with `ZTRACKER_SIGN_ID` + `ZTRACKER_NOTARY_PROFILE` via
  `scripts/make-dmg.sh` (signs + notarizes + staples both arches, writes appcasts),
  then a GitHub Release with the 2 DMGs + 2 appcasts. See `docs/RELEASING.md`.
- A store presence would only be revisited for a hypothetical build stripped of Nintendo
  assets (user-supplied art / abstract markers) — a product change, not a packaging one.
  Not planned.
