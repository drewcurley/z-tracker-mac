# Review: feat/github-sponsors-plug — final (T-225)

**Status:** PASS — a quiet GitHub Sponsors footer link on the startup/settings screen and a weekly,
opt-out-able post-run thank-you banner. User QA'd and approved. Ships as notarized **v1.2.6**.

unanimous-consensus: T-225

## What shipped
- `SponsorFooterLink` at the bottom of the startup/settings screen → `github.com/sponsors/drewcurley`.
- `SponsorCompletionBanner` shown after a finish, at most once a week (`@AppStorage` timestamp), with
  a "Don't show again" opt-out; suppressed on the broadcast/mirror window.

## Sign-offs
- [x] Analyst — matches the request (persistent link + occasional post-completion plug); tasteful,
      not naggy; completion-only trigger + weekly cadence confirmed by the user.
- [x] Architect — no model/persistence changes beyond two `@AppStorage` prefs; the URL is verified
      (HTTP 200) and owned by the repo author; nothing sends user data anywhere.
- [x] Data — n/a.
- [x] Backend — trigger hooks the existing completion `onChange`; gated on `!isMirror` + opt-out +
      the weekly interval.
- [x] Frontend/UX — footer link is subtle and always present; the banner is dismissible with clear
      actions and a remembered opt-out; it uses a distinct (pink) treatment from the green update banner.
- [x] SDET — `SponsorPlugTests` (URL + interval). **789 tests pass.**
- [x] DevOps — clean build/test; ships as notarized dual-arch DMGs + appcasts for v1.2.6.
- [x] Review Coordinator — T-225 filed; INDEX + CHANGELOG (1.2.6) updated; VERSION → 1.2.6.

## Items to address (follow-ups)
- Optional: also surface it occasionally on plain app startup — deferred; the user chose
  completion-only for now.
