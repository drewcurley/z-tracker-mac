# Review: feat/update-check — final (T-174)
**Status:** PASS WITH ITEMS — built + tested; one behavioral choice flagged for the user.
unanimous-consensus: T-174

## Items for the user
- **Network-on-launch, default on.** The update check adds an unauthenticated GET to
  GitHub on launch, gated on a setting that defaults to on. It sends no data and fails
  silently, but it is a new outbound call — confirm the default before merge, or flip it
  to default-off.

## Sign-offs
- [x] **Analyst** — scope is the free distribution path + a passive update notice;
      notarization/Sparkle explicitly out of scope and documented, not half-built.
- [x] **Architect** — the checked URL is hard-coded to the project repo (not derived from
      any observed content), no query params, no user data. Notarization signing is
      env-gated; entitlements limited to audio-input.
- [x] **Data Engineer** — new durable Bool `checkForUpdatesOnLaunch` via the existing
      persistedBoolKeyPaths map; no schema/save-format change.
- [x] **Backend Engineer** — `UpdateChecker` fails silently on every error path (offline,
      non-200, malformed JSON, unparseable tag); `didCheck` prevents repeat fetches.
- [x] **Frontend Engineer** — banner is dismissible and only renders when a strictly
      newer release is found; the check runs from `.task`, off the main path.
- [x] **UX Designer** — the notice is informational + one click to the download, not a
      forced modal; the setting is discoverable and explains it sends no data.
- [x] **SDET** — 659 tests; `AppVersionTests` covers v-prefix, short forms, numeric (not
      lexical) ordering, pre-release suffixes, and garbage-is-safe. Network path is
      failure-silent by construction.
- [x] **DevOps** — `make-dmg.sh` verified to produce a 5.1 MB UDZO dmg; `build-app.sh`
      adds hardened runtime only for Developer ID; RELEASING.md documents both paths.
- [x] **Review Coordinator** — T-174 filed; INDEX updated.
