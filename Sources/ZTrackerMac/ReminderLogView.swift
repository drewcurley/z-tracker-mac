import SwiftUI
import TrackerCore

/// The reminder-log popover (T-102): a most-recent-first list of the reminders
/// that have fired, with a Clear action. The reference's "log" affordance for
/// reviewing past reminders / beep explanations.
struct ReminderLogView: View {
    @Bindable var log: ReminderLog

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Reminder log").font(.headline)
                Spacer()
                Button("Clear") { log.clear() }
                    .font(.caption).controlSize(.small)
                    .disabled(log.entries.isEmpty)
            }
            if log.entries.isEmpty {
                Text("No reminders yet.")
                    .font(.callout).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(log.entries) { entry in
                            Text(entry.text)
                                .font(.system(size: 12))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 1)
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 280)
            }
        }
        .padding(12)
        .frame(width: 300)
    }
}
