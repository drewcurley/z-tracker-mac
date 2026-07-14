import AVFoundation
import SwiftUI
import TrackerCore

/// Renders the `ReminderAnnouncement`s produced by `TrackerModel.reminderEngine`
/// (T-018.2) as spoken and/or on-screen reminders (T-018.3), honoring the
/// per-category Voice/Visual toggles and the volume in `TrackerOptions`.
/// The reference speaks + shows reminders driven by a ~1 Hz poll of
/// `allUIEventingLogic`; this is the Swift equivalent (`AVSpeechSynthesizer`
/// + a transient overlay), grounded in the `SendReminder` call sites
/// (`Z1R_Avalonia/UI.fs:1399-1615`).
@Observable
@MainActor
final class ReminderController {
    struct Item: Identifiable, Equatable {
        let id = UUID()
        let text: String
    }

    /// Currently-shown visual reminders (each auto-dismisses).
    private(set) var visible: [Item] = []

    @ObservationIgnored private let synthesizer = AVSpeechSynthesizer()

    /// How long a visual reminder stays on screen.
    private let visibleDuration: Duration = .seconds(6)
    private let maxVisible = 5

    init() {
        // Warm up the speech service at launch. The first `AVSpeechSynthesizer`
        // utterance is slow (macOS has to spin up the com.apple.speech
        // service — often ~15-20s), so we absorb that latency here with a
        // silent utterance rather than at the first real reminder.
        let warmup = AVSpeechUtterance(string: " ")
        warmup.volume = 0
        synthesizer.speak(warmup)
    }

    /// Speak/show each announcement whose category is enabled.
    func handle(_ announcements: [ReminderAnnouncement], options: TrackerOptions) {
        for announcement in announcements {
            let text = announcement.displayText
            if options.visualReminders[announcement.category] == true {
                show(text)
            }
            if options.voiceReminders[announcement.category] == true {
                speak(text, volume: options.reminderVolume, voiceIdentifier: options.preferredVoiceIdentifier)
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

    private func speak(_ text: String, volume: Int, voiceIdentifier: String?) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.volume = max(0, min(1, Float(volume) / 100))
        if let voiceIdentifier, let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
            utterance.voice = voice
        }
        synthesizer.speak(utterance)
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
