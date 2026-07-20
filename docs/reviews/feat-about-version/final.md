# Review: feat/about-version — final (T-163)
**Status:** PASS — About footer with app version + project link (audit #23, version half).
unanimous-consensus: T-163
## Sign-offs
- [x] Analyst — closes the version/website-button half of audit #23; LEGEND half noted as still open.
- [x] Architect — reads CFBundleShortVersionString (fed from VERSION by build-app.sh); no new state; ties into the versioning earmark.
- [x] Data — none.
- [x] Backend — none; static helper + a Link.
- [x] Frontend — About row in the settings panel; version selectable; external project link.
- [x] UX — surfaces the version where users look for it; link opens on click (user-initiated).
- [x] SDET — tests: version is a v-prefixed non-empty string, project URL is https/github. **624 tests pass**.
- [x] DevOps — no infra; build clean.
- [x] Review Coordinator — T-163 filed; INDEX + audit updated.
