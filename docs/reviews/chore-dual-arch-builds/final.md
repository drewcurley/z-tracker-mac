# Review: chore/dual-arch-builds — final (T-201)

**Status:** PASS — the build now produces dedicated native Apple Silicon **and** Intel DMGs.
Intel slice verified to compile + link (x86_64 binary) on the dev machine.

unanimous-consensus: T-201

## What shipped
- `build-app.sh` arch-aware (`--arch`, default host); `make-dmg.sh` builds both arches into
  `-AppleSilicon.dmg` / `-Intel.dmg`. README + RELEASING updated; `VERSION` → 0.8.1.

## Sign-offs
- [x] Analyst — matches the ask: dedicated per-arch native builds (no universal binary),
      both cut every release.
- [x] Architect — no source change; macOS-14 floor documented (Observation framework);
      Intel Macs on Sonoma+ covered without a refactor.
- [x] DevOps — dual-arch build/package flow; per-DMG notarization loop preserved; artifacts
      stay git-ignored (T-176 precedent).
- [x] SDET — build-only; **730 tests pass**. Intel *runtime* validation deferred to real
      Intel hardware (flagged; a user tester will confirm).
- [x] Backend / Data / Frontend / UX — n/a.
- [x] Review Coordinator — task filed (T-201); INDEX updated.

## Items to address (follow-ups)
- Confirm the Intel build runs on real Intel hardware (tester feedback) — the one thing that
  can't be verified from an Apple-Silicon machine.
