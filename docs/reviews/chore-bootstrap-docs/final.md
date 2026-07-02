# Review: chore/bootstrap-docs — final

**Status:** PASS WITH ITEMS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats. Recorded honestly, not
presented as independent consensus.

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- [ ] Several open decisions are deliberately left unresolved in the docs
      rather than guessed (save-file compatibility, macOS save-directory
      location, deployment target, sprite-rendering approach, "show/run
      custom" confirmation-prompt behavior) — each is tracked in `T-002.md` or
      flagged inline; must not silently slip past that task.
- [ ] `domain.md`'s inventory has explicit UNKNOWNs (routing algorithm
      rule-by-rule detail, hint-decoding tables, sprite-slicing offsets,
      per-dungeon save sub-schema) — implementation tasks for those specific
      features must re-verify against `Zelda1RandoTools` directly rather than
      trusting this doc set alone.

## Suggestions (consider for polish)
- Once T-002 lands, do a pass removing every "forward-looking"/"UNKNOWN"
  marker that's been resolved, so the doc set doesn't accumulate stale caveats.

## Agent Sign-offs
- [x] Analyst — scope matches the docs-bootstrap mandate; no feature work
      snuck in; acceptance criteria in T-001 map to what was actually written.
- [x] Architect — flagged the one real security-relevant surface ("show/run
      custom" arbitrary process/URL launch, `contracts.md` § 3) explicitly
      rather than silently porting it; no other trust-boundary concerns for a
      local, network-free, account-free app.
- [x] Data Engineer — `data-model.md` schema is grounded in the reference
      app's actual save format with explicit UNKNOWNs where sub-schemas
      weren't transcribed; the compatibility decision is correctly left open
      rather than assumed.
- [x] Backend — N/A in the traditional sense (no server); `api.md`'s
      model-layer-boundary framing is a reasonable analog and gives concrete
      rules for the first real implementation task.
- [x] Frontend — `stack.md`'s SwiftUI-with-AppKit-interop choice is
      technically feasible; sprite-rendering approach correctly left as an
      implementation-time decision rather than guessed now.
- [x] UX — `ux.md` carries forward the reference app's three personas and
      primary journeys faithfully; accessibility baseline flagged as
      not-yet-decided but not deferred past the first UI task.
- [x] Test Engineer — `testing.md`'s regression-safety check is concrete
      (contract-level test required, not just unit); notes that CI's
      build/test job is `continue-on-error` until T-002 lands — tracked, not
      hidden.
- [x] DevOps — `deployment.md` and `.github/workflows/checks.yml` are
      consistent; flags that code signing/notarization and branch protection
      are both still open (see `playbook/tasks/T-009.md` warnings).
- [x] Review Coordinator — process followed: T-001 acceptance criteria map to
      the actual doc set; `tasks/INDEX.md` updated in the same change; T-002
      seeded as the natural next task rather than left implicit.

## Lens Sign-offs (major decisions — docs bootstrap + stack ADR qualify)
- [x] CEO — N/A (personal project).
- [x] Purchasing — no new vendor/cost (Apple's own frameworks only; no
      third-party SPM dependency introduced).
- [x] PM — scope correctly bounded to docs; T-002 clearly the next buildable step.
- [x] Adopter — the developer (sole adopter) directly confirmed the "native
      Swift over Avalonia port" direction via the original request.
- [x] Builder — the F#-core-as-spec approach (ADR 0001) gives a maintainer a
      concrete, checkable target rather than "clone this app" vibes.
- [x] Investor — N/A (hobby project, no funding dimension).
- [x] Marketing — N/A at this stage; the "near pixel-perfect, native" hook is
      a clean one to lead with once there's something to show.
