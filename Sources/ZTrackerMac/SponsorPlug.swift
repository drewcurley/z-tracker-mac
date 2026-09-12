import SwiftUI

/// GitHub Sponsors plug (T-225). The author set up Sponsors; this surfaces it in two low-key places:
/// a persistent footer link on the startup/settings screen, and an occasional, dismissible thank-you
/// after a run finishes (rate-limited to at most once a week, with a "don't show again" opt-out).
enum Sponsor {
    static let url = URL(string: "https://github.com/sponsors/drewcurley")!

    // @AppStorage keys for the post-run prompt's rate limiter.
    static let lastPromptKey = "sponsor.lastPromptAt"   // Date.timeIntervalSinceReferenceDate
    static let optOutKey = "sponsor.optOut"             // Bool
    /// Minimum spacing between post-run prompts.
    static let minInterval: TimeInterval = 7 * 24 * 60 * 60
}

/// A quiet one-line footer link — a heart + "Sponsor Z-Tracker on GitHub" — for the bottom of the
/// startup/settings screen. Always present, never nags.
struct SponsorFooterLink: View {
    var body: some View {
        Link(destination: Sponsor.url) {
            HStack(spacing: 6) {
                Image(systemName: "heart.fill").foregroundStyle(.pink)
                Text("Sponsor Z-Tracker on GitHub")
            }
            .font(.callout)
        }
        .buttonStyle(.plain)
        .help("Z-Tracker is free. If it helps your runs, a sponsorship keeps it going — thank you!")
    }
}

/// The occasional post-run thank-you banner (T-225): shown at most once a week after a finish, with a
/// Sponsor button, a "Maybe later" dismiss, and a "Don't show this again" opt-out.
struct SponsorCompletionBanner: View {
    var onDismiss: () -> Void
    var onOptOut: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "heart.fill").foregroundStyle(.pink)
            VStack(alignment: .leading, spacing: 2) {
                Text("Nice run!").fontWeight(.semibold)
                Text("If Z-Tracker helps you, consider sponsoring its development.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Link("Sponsor ↗", destination: Sponsor.url)
                .buttonStyle(.borderedProminent)
            Button("Maybe later") { onDismiss() }
                .buttonStyle(.bordered)
            Button("Don't show again") { onOptOut() }
                .buttonStyle(.plain).font(.caption).foregroundStyle(.secondary)
            Button { onDismiss() } label: { Image(systemName: "xmark").font(.caption) }
                .buttonStyle(.plain).help("Dismiss")
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 8).fill(.pink.opacity(0.12)))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.pink.opacity(0.4)))
        .frame(maxWidth: 620)
    }
}
