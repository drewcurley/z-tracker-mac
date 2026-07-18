# Review: chore/app-bundle — final (T-136)

**Status:** PASS — the app now builds as a signed `.app` bundle with the TCC usage
strings the voice feature needs.

unanimous-consensus: T-136

## Scope
Infra/config only: a `.app` wrapper + build script. No application logic changed.
Config/infra tier → Architect + Ops the primary reviewers.

## Sign-offs
- [x] Analyst — scope is exactly the voice prerequisite; versioning/self-update only
      *earmarked* (version fields wired), not built.
- [x] Architect — stable bundle id `com.drewcurley.ztracker-mac` + ad-hoc signature give
      TCC a persistent identity to attach the mic/speech grant to; usage strings present
      (a bare binary would be killed on first mic request). Min-OS/principal-class set.
- [x] Ops/DevOps — `scripts/build-app.sh` is reproducible (`swift build` → assemble →
      sign); `.app` is git-ignored; version is single-sourced from `VERSION`.
- [x] Backend/Frontend — no source change; the running app is byte-identical, just wrapped.
- [x] Data — none.
- [x] UX — launch path becomes `open ZTrackerMac.app`; behavior unchanged.
- [x] SDET — resource resolution verified (sprites render from `Bundle.module` inside the
      bundle); full suite green (545). Signing/plist asserted via `codesign -dv` / `plutil`.
- [x] Review Coordinator — task filed (T-136); INDEX updated.

## Regression safety
- Pure additive packaging; the dev binary at `.build/.../ZTrackerMac` is unchanged and
  still runnable for quick iteration. The `.app` is only needed once the voice feature
  requests the mic.

## Follow-ups
- T-137 — voice control (Speech.framework) now unblocked.
- Versioning + self-update system (earmarked; version fields already in the bundle).
