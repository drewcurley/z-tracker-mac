# Review: fix/resource-bundle-infoplist — final (T-202)

**Status:** PASS — fixes the macOS 15 (Sequoia) launch crash (`Bundle.module` fatalError) by
giving the SwiftPM resource bundle a valid `Info.plist`. Bug-fix scope (Backend/DevOps + SDET).

unanimous-consensus: T-202

## Root cause
SwiftPM's resource bundle had no `Info.plist`; Sequoia's `Bundle(url:)` rejects a plist-less
`.bundle`, so `Bundle.module` traps at launch. Affected **both** arches (macOS 26 dev box was
lenient, hiding it). Not an Intel/ISA issue — the SIGILL is a Swift `fatalError` trap.

## Fix
`build-app.sh` writes a minimal flattened `Info.plist` into the bundle before signing.
`VERSION` → 0.8.2.

## Sign-offs
- [x] Analyst — matches the tester's crash report exactly; scoped to the packaging fix.
- [x] Architect — resource layout unchanged (flattened, resources at root); plist only
      satisfies `Bundle(url:)` validation; sealed by the signature.
- [x] DevOps — build produces a valid, lint-clean, signed bundle; both arches re-released.
- [x] SDET — 730 tests pass; bundle verified (plist present, `plutil -lint` OK, Rosetta
      launch clean). Sequoia confirmation deferred to the tester (documented).
- [x] Backend / Frontend / Data / UX — n/a.
- [x] Review Coordinator — task filed (T-202); INDEX updated.

## Items to address (follow-ups)
- Tester on real Sequoia to confirm the launch fix. If any future SwiftPM/toolchain change
  restores a bundle Info.plist on its own, the guard is idempotent (only writes if absent).
