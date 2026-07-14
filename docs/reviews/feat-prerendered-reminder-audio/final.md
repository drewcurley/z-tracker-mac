# Review: feat/prerendered-reminder-audio — final

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats.

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- [ ] The audio *sound* (voice quality, prompt playback) is user-verified —
      sample clips (`afplay`) confirmed the files are valid and render the Zoe
      voice; the user confirms it in-app.
- [ ] The in-app voice-*picker* option (`preferredVoiceIdentifier`) no longer
      affects spoken reminders (they're pre-rendered). Re-render with a
      different voice to change it; the picker only matters for the rare live-
      TTS fallback. Consider hiding/relabeling the picker later.

## Suggestions (consider for polish)
- The generator hardcodes the Zoe voice; parameterizing it (voice arg through
  the Swift tool) would let `generate-reminder-audio.sh "Some Voice"` work.

## Agent Sign-offs
- [x] Analyst — scope: replace spoken TTS with pre-rendered clips (the user's
      idea), fixing latency/races + naturalness. Bounded clip set covers every
      announcement; the one variable case (unblock dungeon list) is rendered
      per-blocker. No scope creep into other reminder behavior.
- [x] Architect — no security surface. `AVAudioPlayer` playback is local +
      instant; no network, no service spin-up. Clips are bundled resources.
      Live TTS remains as a graceful fallback.
- [x] Data Engineer — the ~40 clip keys are a closed set matched 1:1 between
      `ReminderAnnouncement.audioKey` and the generator; a test asserts every
      key's file exists (no danglers).
- [x] Backend — N/A (no server); the generator is a dev-time Swift tool.
- [x] Frontend — `ReminderController` prefers the clip (`audio.play`) and only
      falls back to `speak` when there's no clip; the T-023 warm-up hack is
      removed. `ReminderAudioPlayer` retains players while playing (an
      `AVAudioPlayer` stops if deallocated) and reaps finished ones.
- [x] UX — spoken reminders are now instant and natural (neural Zoe) instead
      of a laggy classic-TTS voice — a clear quality lift the user requested.
      Volume still honors `reminderVolume`; per-category voice toggles still
      gate playback.
- [x] Test Engineer — `audioKey` mapping tested (every case → its bounded
      clip name, incl. maybe-blocker via `hardCanonical` and the 4 TAG
      levels), plus a build-time check that every key has a matching `m4a`.
      Sample clips played via `afplay`. 217/217 total.
- [x] DevOps — no CI/deploy changes; assets are 532KB committed. The generator
      is reproducible (`scripts/generate-reminder-audio.sh`). `swift build` +
      `swift test` clean.
- [x] Review Coordinator — `tasks/T-024.md` filed; INDEX regenerated. (No
      `docs/*` domain change — this changes *how* reminders are voiced, not
      *what* they announce, which is unchanged from T-018.2/.3.)

## Lens Sign-offs (a user-requested UX upgrade)
- [x] Adopter — the tracker now talks to you *immediately* and *naturally* —
      the single most noticeable rough edge from playtesting, fixed.
- [x] Builder — the run-loop Swift generator (voice loaded once) is the key
      insight that made neural rendering feasible (`say` per-clip = ~60s);
      committed + reproducible.
- Other lenses — N/A (local UX polish).

## Regression safety
- Contracts touched = none (in-process; a new `audioKey`, a new player, bundled
  assets). Cross-repo = none. Compatibility = additive; spoken-reminder path
  swapped clip-first with TTS fallback (no announcement content changed).
- Full suite: 216/216 → 217/217, no regressions. `swift build` clean; app runs.

## Out of scope (follow-ons)
- Parameterizing the generator voice; hiding/relabeling the now-moot voice
  picker; per-voice clip sets if multiple voices are ever wanted.
