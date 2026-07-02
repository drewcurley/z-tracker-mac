# Review: chore/initial-scaffold — final

**Status:** PASS WITH ITEMS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats.

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- [ ] No `.app` bundle / code signing yet — `swift run` launches a bare
      process, not a distributable, notarized app. Deferred per `deployment.md`
      (unchanged by this task; still forward-looking there).
- [ ] Coverage is trivial (5 tests over 2 small units) — expected for a
      scaffold; the first real feature task must not treat this as an
      established coverage bar.
- [ ] `SaveDirectoryLocatorTests` writes to the real
      `~/Library/Application Support/com.drewcurley.ztrackermac/` on the
      machine running the test — acceptable for a scaffold-stage test but
      worth revisiting (a temp-directory override) once more tests touch
      persistence, so the suite doesn't depend on real filesystem side effects.

## Suggestions (consider for polish)
- Consider adding `swift test --enable-code-coverage` to CI now (even without
  a gate) so coverage trend is visible before it matters.

## Agent Sign-offs
- [x] Analyst — scope matches T-002 exactly: scaffold + the three deferred
      decisions, nothing more (no tracker features implemented).
- [x] Architect — no security posture concerns; `SaveDirectoryLocator` uses
      the standard sandboxed-friendly Application Support location; bundle
      identifier chosen (`com.drewcurley.ztrackermac`) for future
      signing/entitlements work. Flags the Application-Support-in-tests point
      above as a warning, not a blocker.
- [x] Data Engineer — save/settings location decision resolved and
      implemented with a real, tested locator; `data-model.md` updated in
      this same PR per the regression-safety convention this project set for
      itself in `docs/README.md`.
- [x] Backend — model-layer boundary from `api.md` § 1 is honored:
      `TrackerModel` is UI-agnostic, `ContentView` only reads it.
- [x] Frontend — SwiftUI app target builds and runs a real window on Apple
      Silicon; sprite-rendering approach decided (not yet implemented, no
      sprites needed for this scaffold).
- [x] UX — placeholder content view is honest about its own status ("no
      tracker UI yet") rather than looking finished; no UX surface to review yet.
- [x] Test Engineer — `swift test` runs 5 real (non-trivial, non-tautological)
      tests, all passing; CI's `build-and-test` job no longer has
      `continue-on-error` — it's a real gate now, not a placeholder.
- [x] DevOps — CI verified green end-to-end on this branch's own PR (see PR
      checks); no infra/deploy change beyond removing the CI relaxation.
- [x] Review Coordinator — process followed: T-002 acceptance criteria map
      1:1 to what shipped; `tasks/INDEX.md` regenerated in the same change.

## Lens Sign-offs (major decisions — the 3 resolved UNKNOWNs qualify)
- [x] CEO — N/A (personal project).
- [x] Purchasing — no new cost; zero third-party SPM dependencies added.
- [x] PM — unblocks all future feature tasks by resolving the docs' open
      decisions instead of letting them accumulate.
- [x] Adopter — the developer (sole adopter) ran the app locally (`swift run`)
      to confirm it launches before this was called done.
- [x] Builder — Swift Testing's parameterized tests are a small but real
      quality-of-life win recorded honestly as a documented decision, not a
      silent tooling drift.
- [x] Investor — N/A.
- [x] Marketing — N/A at this stage.
