import SwiftUI

/// The launch "resume your last run?" prompt (T-192). Unlike a plain confirmation
/// dialog, it **auto-resumes after 5 seconds** so a crash-recovered session picks up
/// on its own if you walk away — the common case being "the app crashed mid-run and I
/// forgot to restart the timer." The countdown pauses while the pointer is over the
/// card and stops for good once any button is pressed, so it never fires out from under
/// a deliberate choice.
struct ResumeSessionPrompt: View {
    /// When the offered session was auto-saved.
    let savedAt: Date
    /// Resume now (also fired automatically when the countdown hits zero).
    let onResume: () -> Void
    /// Discard the saved session and start fresh.
    let onDiscard: () -> Void
    /// Dismiss without resuming or discarding (keeps the save for next launch).
    let onCancel: () -> Void

    /// Seconds until auto-resume.
    private static let countdownStart = 5

    @State private var remaining = ResumeSessionPrompt.countdownStart
    /// Countdown runs until the pointer enters the card or a button is pressed.
    @State private var counting = true
    @State private var hovering = false

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Dim the startup screen behind the modal.
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            card
                .onHover { hovering = $0 }
        }
        .onReceive(tick) { _ in
            guard counting, !hovering else { return }
            if remaining > 1 {
                remaining -= 1
            } else {
                counting = false
                onResume()
            }
        }
        .transition(.opacity)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title2)
                    .foregroundStyle(.green)
                Text("Resume your last run?")
                    .font(.title2.bold())
            }

            Text("An unfinished run was auto-saved on \(savedFormatted). "
                 + "It will reopen and the timer will resume automatically.")
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(.secondary)

            // The live countdown (or a "paused" note while hovering / after a choice).
            Group {
                if counting && !hovering {
                    Text("Resuming in \(remaining)…")
                        .monospacedDigit()
                        .fontWeight(.semibold)
                } else {
                    Text("Auto-resume paused — choose below.")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.callout)

            Divider()

            HStack {
                Button("Discard", role: .destructive) {
                    counting = false
                    onDiscard()
                }
                Spacer()
                Button("Not now") {
                    counting = false
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                Button("Resume now") {
                    counting = false
                    onResume()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 440)
        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.cardFill))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border))
        .shadow(radius: 20)
    }

    private var savedFormatted: String {
        DateFormatter.localizedString(from: savedAt, dateStyle: .medium, timeStyle: .short)
    }
}

#Preview {
    ResumeSessionPrompt(savedAt: .now, onResume: {}, onDiscard: {}, onCancel: {})
        .frame(width: 640, height: 480)
}
