# Review: feat/reminder-engine — final

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats. Carries the **architecture
decision** T-018 flagged; reviewed below.

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- [ ] Nothing renders the announcements yet — `poll` returns them but no
      timer calls it and no speech/visual surface presents them. That's
      T-018.3 (needs a reminder UI surface). The engine is fully tested
      independently.
- [ ] `HasBeenLocated` is approximated by `mapState.dungeonLocations[d] != nil`
      (differs from the reference only for dungeons marked on always-empty
      screens — a nonsensical action). Documented in the type.

## Suggestions (consider for polish)
- When T-018.3 wires the poll, add a `TrackerModel` convenience that assembles
  the six `poll` inputs (it has or can derive them all).

## Agent Sign-offs
- [x] Analyst — **architecture decision reviewed and endorsed.** The task's
      open question (reactive `@Observable` vs. literal `ITrackerEvents`
      delegate) is resolved by consulting the source: the delegate's
      callbacks split into state-push (redundant under `@Observable`, which
      the whole project already uses) and edge-triggered announcements (the
      real logic). Porting only the latter, as `poll -> [Announcement]`, is
      the faithful *and* idiomatic choice; a literal delegate port was
      considered and rejected with a documented reason. Scope is the engine;
      rendering is T-018.3.
- [x] Architect — no security surface; a self-contained stateful engine with
      no globals (the reference's ~18 module-level `prior*`/`haveAnnounced*`
      mutables become private fields).
- [x] Data Engineer — the edge-detection is transcribed block-for-block
      against `allUIEventingLogic` (`:1571-1744`): heart thresholds
      (4–6/10–14, once each), completion/found/triforce counts, the three-way
      TAG-announce logic with its `justAnnouncedTAG` guard (`:1644-1667`), the
      combat-unblocker sword/wand/ring rules + origin exclusion (`:1668-1701`),
      the generic `hardCanonical`-matched blocker logic (`:1702-1735`), the
      `< 103` TAG suppression gate, and the one-shot item nudges. `calcFrom-
      Dungeon` and the reset's deliberate non-resets preserved.
- [x] Backend — N/A (no server); pure logic over its inputs + private state.
- [x] Frontend — N/A (no UI this task; the returned announcements are what a
      view/speech layer will render in T-018.3).
- [x] UX — N/A (rendering deferred); the announcement *set* matches the
      reference's, so the eventual surface has parity to render.
- [x] Test Engineer — 14 scenario tests: fresh-empty, consider-sword2 (fires
      once / suppressed by item), consider-sword3, completed-dungeon
      (once-only), found-count, triforce-count (once-only), triforce-and-go,
      generic ladder unblock + item nudge, maybe-blocker via hardCanonical,
      completed-dungeon-not-unblocked, combat unblock on sword upgrade, the
      full-TAG (103) blocker suppression, and groundhog-reset re-arming.
      189/189 total.
- [x] DevOps — no CI/deploy changes; `swift build` + `swift test` clean.
- [x] Review Coordinator — process followed; `domain.md` § 6 + umbrella
      `T-018.md` + `tasks/T-018.2.md` (rewritten) + `tasks/T-018.3.md`
      (created) updated; INDEX regenerated.

## Lens Sign-offs (the architecture decision is the notable one)
- [x] Builder — resolving `ITrackerEvents` to `poll -> [Announcement]` keeps
      the engine pure-logic and exhaustively testable without a running UI,
      and matches every prior port's `@Observable`-over-events choice.
- [x] PM — shipping the tested engine now and deferring only the rendering
      surface (T-018.3) closes the last big *logic* gap in the state arc.
- Other lenses — N/A (internal engine; the user-facing surface is T-018.3).

## Regression safety
- Contracts touched = none (in-process engine). Reflected in docs = yes
  (`domain.md` § 6). Cross-repo consumers = none. Compatibility = additive.
- Full suite: 175/175 → 189/189, no regressions. `swift build` clean.

## Out of scope (tracked as follow-ons)
- T-018.3 — announcement rendering (speech + visual reminder surface + poll
  loop).
- Recorder-warp destinations (T-015.5) and timeline data — noted, not part of
  the engine.
