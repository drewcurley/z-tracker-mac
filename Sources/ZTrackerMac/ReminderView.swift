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
        var action: ToastAction? = nil
        static func == (a: Item, b: Item) -> Bool { a.id == b.id }
    }
    /// A button on a toast, e.g. the groundhog reset's "Undo" (T-246).
    struct ToastAction {
        let title: String
        let perform: @MainActor () -> Void
    }

    /// Currently-shown visual reminders (each auto-dismisses).
    private(set) var visible: [Item] = []
    /// A running log of the reminders that fired (T-102), for the Log popover.
    let log = ReminderLog()

    /// How long a visual reminder stays on screen.
    private let visibleDuration: Duration = .seconds(6)
    private let maxVisible = 5

    /// Speak/show each announcement whose category is enabled, and log it. Voice
    /// reminders go to the shared `SpeechEngine`, which serializes them (no overlap).
    func handle(_ announcements: [ReminderAnnouncement], options: TrackerOptions,
                hideDungeonNumbers: Bool = false, assignedLabels: [Character] = [],
                elapsedSeconds: Int = 0, swordLevel: Int = 0, ringLevel: Int = 0,
                coastItemId: Int? = nil) {
        for announcement in announcements {
            let text = announcement.displayText(hideDungeonNumbers: hideDungeonNumbers,
                                                assignedLabels: assignedLabels)
            let visual = options.visualReminders[announcement.category] == true
            let voice = options.voiceReminders[announcement.category] == true
            if visual { show(text) }
            if voice {
                SpeechEngine.speak(text,
                                   volume: Float(options.reminderVolume) / 100,
                                   preferredVoiceIdentifier: options.preferredVoiceIdentifier)
            }
            // Log any reminder the player was actually surfaced (shown or spoken),
            // with its fire-time and descriptive icons (T-122).
            if visual || voice {
                let icons = ReminderIcons.icons(for: announcement, swordLevel: swordLevel,
                                                ringLevel: ringLevel, coastItemId: coastItemId)
                log.append(text, elapsedSeconds: elapsedSeconds, icons: icons)
            }
        }
    }

    /// A brief on-screen hint that isn't a reminder (not spoken, not logged) — e.g. the
    /// "press again" prompt for a guarded hotkey (T-239).
    /// With an `action`, the toast shows a button; tapping it runs the action and dismisses
    /// the toast.
    @discardableResult
    func toast(_ text: String, duration: Duration = .seconds(2), action: ToastAction? = nil) -> UUID {
        show(text, duration: duration, action: action)
    }

    func dismiss(_ id: UUID) {
        visible.removeAll { $0.id == id }
    }

    @discardableResult
    private func show(_ text: String, duration: Duration? = nil, action: ToastAction? = nil) -> UUID {
        let item = Item(text: text, action: action)
        visible.append(item)
        // Over the cap, drop the oldest plain reminders first so a burst of them can't push an
        // actionable toast (Undo) off screen early.
        while visible.count > maxVisible {
            let i = visible.firstIndex { $0.action == nil } ?? 0
            visible.remove(at: i)
        }
        let wait = duration ?? visibleDuration
        Task { [weak self] in
            try? await Task.sleep(for: wait)
            self?.dismiss(item.id)
        }
        return item.id
    }

}

/// A transient stack of reminder "toasts".
struct ReminderOverlayView: View {
    var controller: ReminderController

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(controller.visible) { item in
                HStack(spacing: 10) {
                    Text(item.text)
                    if let action = item.action {
                        Button(action.title) {
                            controller.dismiss(item.id)
                            action.perform()
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.accentColor)
                    }
                }
                .font(.callout.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(.black.opacity(0.82), in: Capsule())
                .transition(.move(edge: .top).combined(with: .opacity))
                .accessibilityAddTraits(.updatesFrequently)
                // Only toasts with a button take clicks; plain ones never block the board.
                .allowsHitTesting(item.action != nil)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: controller.visible)
    }
}
