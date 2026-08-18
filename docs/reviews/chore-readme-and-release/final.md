# Review: chore/readme-and-release — final (T-198)

**Status:** PASS — README rewritten to be app/user-facing (no playbook/harness), and a first
tester DMG published as a GitHub Release.

unanimous-consensus: T-198

## What shipped
- `README.md`: app description (a **spiritual successor**, not a pixel-perfect clone),
  requirements, install with the unsigned first-launch note, feature tour, data files, credit.
  All development-harness references removed.
- Tester release: `ZTrackerMac-<version>.dmg` built via `scripts/make-dmg.sh` and attached to a
  GitHub Release with install instructions.

## Sign-offs
- [x] Analyst — matches the ask (feature-focused README; distributable build).
- [x] Architect — no code/security change; the DMG stays unsigned (documented) — no secrets
      committed, no artifact tracked in-repo (T-176 precedent).
- [x] Frontend / UX — README reads for a Z1R player on a Mac; install friction called out.
- [x] DevOps — `make-dmg.sh` builds release config; notarization path documented for later.
- [x] SDET — docs/release only; suite green (**730**), no code touched.
- [x] Backend / Data — n/a.
- [x] Review Coordinator — task filed (T-198); INDEX updated.

## Items to address (follow-ups)
- Clean double-click installs need notarization (paid Apple Developer account) — not blocking
  tester distribution; testers use right-click→Open once.
