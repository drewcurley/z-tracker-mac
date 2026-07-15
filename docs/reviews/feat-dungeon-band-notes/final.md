# Review: feat/dungeon-band-notes — final (T-019.1)

**Status:** PASS — Notes box (first dungeon-band slice) + app keyboard-focus fix.

unanimous-consensus: T-019.1

## Sign-offs
- [x] Analyst — scope: the first frame-first slice of the dungeon band (Notes) +
      the keyboard-focus fix it surfaced. Room grid / blockers / Summary are later
      slices per `docs/design/dungeon-tracker.md`. In scope.
- [x] Architect — the activation-policy fix (`.regular` + activate) is the correct
      remedy for an unbundled executable that can't become key; harmless for a
      bundled build (which already gets `.regular`). Notes is a plain model
      `String`; no persistence coupling yet.
- [x] Data — `notes` is knowledge, so `resetForGroundhogOrRouters` (which never
      touches it) keeps it — matching `levelHints`. Defaults empty.
- [x] Frontend — `NotesView` = `TextEditor` + placeholder overlay (TextEditor has
      no native placeholder); slotted in a `TopSectionGroup("Notes")` below the
      recorder bar. `@NSApplicationDelegateAdaptor` wires the AppDelegate.
- [x] UX — the note box reads as intentional band scaffolding; lime-on-dark nods
      at the reference. The keyboard fix makes every text field (and future
      hotkeys) actually usable.
- [x] SDET — `GroundhogResetTests` extended: default empty + survives reset.
      340/340. On-device with a **real keypress** (synthetic input can't take key
      focus reliably): typing shows green text; the note persists across "Reset
      (keep maps)".
- [x] Backend / DevOps — N/A.
- [x] Review Coordinator — task filed (T-019.1); INDEX updated; scoping doc added
      at `docs/design/dungeon-tracker.md`.

## Regression safety
- Additive: one model field (defaulted), one new view, one band section, one
  AppDelegate. The AppDelegate only sets activation policy + activates — no
  behavior change to existing views. Build clean debug + release, 340/340.

## Note
- The keyboard-focus bug was user-reported (caret blinked but keystrokes reached
  another app) and is a real foundational fix, not Notes-specific — bundled here
  because Notes was unusable without it and it was surfaced by this slice.
