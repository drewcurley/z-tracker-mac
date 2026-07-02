# Contracts — z-tracker-mac

**Status:** forward-looking / PLANNED. No code exists yet — every entry below is
a planned contract, ported from the reference app's proven surface (see
`domain.md` for the full grounded inventory this is derived from), not a
descriptive inventory of code that exists in this repo. Do not treat "planned"
entries as implemented; check the actual code before relying on any of them
once implementation begins, and move an entry from PLANNED → IMPLEMENTED in the
same PR that builds it (§ 6.0 grounding — descriptive and forward-looking must
never blur).

This is the single most important doc for safe autonomous commits once
implementation starts: before adding/changing anything below, treat it as a
contract change per `playbook/AGENTS.md` § 7 (update this file in the same PR).

## 1. Local persistence contracts (files)

| # | Contract | Status | Shape | Invariant | Blast radius if broken |
|---|---|---|---|---|---|
| 1 | Save file (autosave) | PLANNED | JSON, `Codable` struct mirroring the reference schema in `data-model.md` § 2 | Written on a periodic timer (reference: ~1 min); must never corrupt a prior valid save on partial write (write-to-temp-then-rename) | User loses in-progress tracking state on crash |
| 2 | Save file (manual) | PLANNED | Same schema as #1, timestamped filename | Triggered only by explicit user action ("Save") | User can't recover a deliberately-saved checkpoint |
| 3 | Save file (finished) | PLANNED | Same schema as #1, timestamped filename | Triggered on Ganon+Zelda completion (opt-in via an option, per `domain.md` § 4.9) | Loses the completion record / timeline export |
| 4 | Options/settings file | PLANNED | JSON, separate from save-state | Independent lifecycle from saves — must load correctly even with no save file present | App starts with wrong/lost user preferences |
| 5 | Save-file schema version / backward compatibility | PLANNED — **decision open**, see `domain.md` § 6 and `data-model.md` § 4 | N/A until the compatibility decision is made | A loader must never silently misinterpret an old-version file as the current version | Silent data corruption on load — this is why the decision must be made before #1–#3 ship, not after |
| 6 | Hotkey config file | PLANNED | User-editable text file, 7 contexts (see `domain.md` § 4.11) | Global-context keys must be unique; non-global contexts may reuse keys — this invariant must be validated at load time, not assumed | A silently-broken hotkey file could make the app unusable mid-race for a seed runner — validate and surface errors, don't fail silently |
| 7 | User-custom checklist file | PLANNED | Small JSON (background image path + labeled checkboxes + optional timeline-logging flag) | Purely additive/optional feature; malformed file must degrade gracefully (feature disabled), never crash the app | Loss of a nice-to-have feature, not core tracking — must not be allowed to crash core tracking |
| 8 | "Show/Run Custom" config file | PLANNED — **security-relevant, see § 3** | User-editable text file: `SHOW <image path>` / `RUN <executable or URL>` entries | This is a deliberate power-user feature (launch arbitrary local executables/URLs the user configured), not an accidental one — the Architect hat must sign off on how this is implemented (e.g., confirmation prompt before executing, sandboxing considerations) before it ships | Launching arbitrary processes from a config file is a real attack surface if the file can be replaced by anything other than the user themselves |
| 9 | Extra-icons asset folder | PLANNED | User-provided image files in a well-known folder, referenced by the draw-layer feature | Purely additive; missing/malformed folder must degrade gracefully | Loss of a customization feature only |

## 2. Local integrations (not network APIs — see § 0 of `architecture.md`)

| # | Contract | Status | Shape | Invariant |
|---|---|---|---|---|
| 1 | OBS "window capture" convention | PLANNED | App window (or dedicated broadcast window) has a stable, documented title string and fixed pixel dimensions (768/512/256 — see `domain.md` § 4.13) | Changing the window title or the fixed broadcast-window sizes is a **breaking contract change** for every streamer's existing OBS scene — treat as seriously as an API breaking change; if changed, document a migration note |
| 2 | Speech synthesis (`AVSpeechSynthesizer`) | PLANNED | In-process macOS framework call, not a network call | No credential, no network — purely a platform API surface |
| 3 | Speech recognition (`SFSpeechRecognizer`) | PLANNED | In-process macOS framework call; requires microphone + speech-recognition usage-description entitlements | Must degrade gracefully (feature disabled) if the user denies permission — never crash |
| 4 | Gamepad input (`GameController` framework) | PLANNED | In-process macOS framework call | Purely additive input method; must not be required for any feature to be usable via mouse/keyboard alone |

## 3. Security-relevant surface (Architect redline territory)

The **only** genuinely security-relevant surface in this entire app is the
"Show/Run Custom" feature (§ 1, entry 8): a user-editable local config file
that can launch arbitrary executables or open arbitrary URLs. This is inherited
intentionally from the reference app (a documented, opt-in power-user feature
for showing custom images/running custom tools during a race), not something
to silently drop or silently keep as-is. Before implementing:
- Confirm the file can only be edited by the same local user who runs the app
  (no privilege boundary is crossed — this is not a remote/multi-user contract).
- Decide whether to prompt for confirmation before executing an entry, matching
  or exceeding the reference app's posture (**UNKNOWN — needs human
  confirmation** what the reference app's exact behavior is here; not
  determined during the inventory pass).

## 4. What this app explicitly does NOT have (stated, not omitted)

- **No network API, routes, or endpoints of any kind.**
- **No environment variables** — the app takes no configuration from the
  process environment; all configuration is the files in § 1.
- **No feature flags** — not used by this project (no server to manage them).
- **No cron jobs / scheduled background work** beyond the in-process autosave
  timer (§ 1, entry 1), which is an app-internal timer, not a system-level job.
- **No database** — see `data-model.md`.
- **No authentication/authorization surface** — single local user, no accounts.
- **No emulator/game-memory integration of any kind** — confirmed in the
  reference app (`domain.md` § 3); this design carries that forward.

## Update-this-doc-when

Update this file in the same PR that implements any entry above (move
PLANNED → IMPLEMENTED with real file paths/type names), or that adds a new
local-file or platform-integration contract not listed here. This is a
`/docs/*` change — see `playbook/AGENTS.md` § 8 hard gates.
