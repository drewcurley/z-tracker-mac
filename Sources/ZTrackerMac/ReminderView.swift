import SwiftUI
import TrackerCore

/// Renders the `ReminderAnnouncement`s produced by `TrackerModel.reminderEngine`
/// (T-018.2) as spoken and/or on-screen reminders (T-018.3), honoring the
/// per-category Voice/Visual toggles and the volume in `TrackerOptions`.
/// The reference speaks + shows reminders driven by a ~1 Hz poll of
/// `allUIEventingLogic`; this is the Swift equivalent, grounded in the
/// `SendReminder` call sites (`Z1R_Avalonia/UI.fs:1399-1615`).
///
/// **Voice is live TTS (T-069), spoken through the shared `SpeechEngine`.** Its
/// one `AVSpeechSynthesizer` queues utterances, so a batch speaks sequentially
/// rather than overlapping (fixes T-068), and the launch warm-up removes the
/// first-use lag that once justified pre-rendered clips (T-024, now retired).
@Observable
@MainActor
final class ReminderController {
    struct Item: Identifiable, Equatable {
        let id = UUID()
        let text: String
    }

    /// Currently-shown visual reminders (each auto-dismisses).
    private(set) var visible: [Item] = []

    /// How long a visual reminder stays on screen.
    private let visibleDuration: Duration = .seconds(6)
    private let maxVisible = 5

    /// Speak/show each announcement whose category is enabled. Voice reminders go
    /// to the shared `SpeechEngine`, which serializes them (no overlap).
    func handle(_ announcements: [ReminderAnnouncement], options: TrackerOptions) {
        for announcement in announcements {
            let text = announcement.displayText
            if options.visualReminders[announcement.category] == true {
                show(text)
            }
            if options.voiceReminders[announcement.category] == true {
                SpeechEngine.speak(text,
                                   volume: Float(options.reminderVolume) / 100,
                                   preferredVoiceIdentifier: options.preferredVoiceIdentifier)
            }
        }
    }

    private func show(_ text: String) {
        let item = Item(text: text)
        visible.append(item)
        if visible.count > maxVisible {
            visible.removeFirst(visible.count - maxVisible)
        }
        Task { [weak self] in
            try? await Task.sleep(for: self?.visibleDuration ?? .seconds(6))
            self?.visible.removeAll { $0.id == item.id }
        }
    }

}

/// A transient stack of reminder "toasts".
struct ReminderOverlayView: View {
    var controller: ReminderController

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(controller.visible) { item in
                Text(item.text)
                    .font(.callout.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.82), in: Capsule())
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .accessibilityAddTraits(.updatesFrequently)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: controller.visible)
        .allowsHitTesting(false)
    }
}
