# Runbook: corrupted or unreadable save file

**Status:** forward-looking — written ahead of the persistence code
(`data-model.md`) landing, so the app can be built to make this runbook true
from day one rather than retrofitted after a user loses a run.

## Symptom

The app fails to load a save file (autosave, manual, or finished — see
`data-model.md` § 1), or loads it with obviously wrong state.

## Likely causes

- Partial write interrupted by a crash/force-quit (mitigated by write-to-temp-
  then-rename — see `contracts.md` § 1 entry 1's invariant; if this runbook is
  ever needed, that invariant may not have been implemented correctly).
- A schema-version mismatch beyond the tolerated backward-compatibility window
  (`data-model.md` § 2 "Backward compatibility").
- Manual hand-editing of the JSON file by the user.

## Response

1. **Never overwrite a file that fails to load.** Always fail into a safe,
   read-only diagnostic state rather than silently writing a fresh/blank save
   over it — the user's most recent successful autosave/manual save is often
   still on disk and recoverable even if the *latest* file is bad.
2. Check for the next-most-recent autosave/manual/finished file in the save
   directory (`data-model.md` § 1) — since saves are timestamped (manual/
   finished) or a single rolling file (autosave), a prior manual save is often
   available even if autosave is corrupted.
3. If the file's `Version` field doesn't match what the app expects and is
   more than one version back, this is expected-unsupported per the reference
   app's own "one version back" policy (`data-model.md` § 2) — surface a clear
   message to the user rather than a crash or silent misinterpretation.
4. If none of the above resolves it, this is a bug — file it as a task, and
   add a fixture from the corrupted file (with any personal notes redacted) to
   the test suite per `testing.md`, so the specific corruption mode gets a
   regression test.

## Update-this-doc-when

Update this runbook once the actual save/load code exists and this response
can be verified against real error messages/behavior instead of the intended
design.
