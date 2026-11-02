# Review: chore/release-hardening — final (T-242, T-243)

**Status:** PASS — the release pipeline fails fast and fails safe, signs and verifies everything it
publishes, and shows users release notes; the voice log is private and opt-in; the dependency and
repo hygiene gaps are closed. Not yet released (CHANGELOG Unreleased).

unanimous-consensus: T-242
unanimous-consensus: T-243

## Sign-offs
- [x] Analyst — scoped to the audit's §2 items that can be done in-repo; owner-only actions listed on T-243.
- [x] Architect — no new trust surface; update URL constrained; signing material blocked from git;
      Sparkle pinned to a patched version; log moved out of shared /tmp with no-follow + 0600.
- [x] Data — n/a.
- [x] Backend — `VoiceDebugLog`, `trustedReleaseURL` are small, pure/injectable units.
- [x] Frontend/UX — Sparkle's update dialog now shows the version's notes (from CHANGELOG) plus a
      full-history link.
- [x] SDET — `SecurityHygieneTests` (log off by default, 0600, symlink refused, URL validation);
      scripts: `bash -n` + ShellCheck clean, preflight failure/success paths exercised, notes
      extraction checked. **823 tests pass.**
- [x] DevOps — `RELEASING.md` matches the scripts; partial-failure recovery documented; full signed
      run happens at the next release (first real exercise of the staging/notary-JSON path).
- [x] Review Coordinator — tasks filed; INDEX + CHANGELOG updated.

## Follow-ups
- SwiftBuild backend stamps the binary with `sdk 14.0` (vs the real SDK under the native backend):
  decide deliberately whether to pin `--build-system native` (may change macOS 26 UI behavior —
  needs a visual check) — left as an owner decision.
- `hdiutil create` deprecation warning — switch to `diskutil image` later.
