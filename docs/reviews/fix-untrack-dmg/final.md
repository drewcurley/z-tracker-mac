# Review: fix/untrack-dmg — final (T-176)
**Status:** PASS — untracks a build artifact; no code change.
unanimous-consensus: T-176

## Sign-offs
- [x] DevOps — the dmg was committed in T-174 despite `dist/` being gitignored (ignore
      doesn't untrack an already-staged path). Removed from tracking; `.gitignore` keeps
      it out. History not rewritten (main is published) — acceptable for a build artifact.
- [x] Analyst/Architect/Data/Backend/Frontend/UX/SDET — no source, schema, or test change;
      654 tests unaffected.
- [x] Review Coordinator — T-176 filed; INDEX updated.
