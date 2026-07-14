import SwiftUI

/// The run-timer display (T-035.4): the main `H:MM:SS.mmm` stopwatch (green
/// running / orange paused) with, once a groundhog reset has happened, a
/// smaller **yellow lap** timer beneath it, plus Pause/Resume + Reset controls.
/// A `TimelineView` refreshes it ~30×/sec so the milliseconds tick smoothly;
/// the values themselves come from `TrackerTimer`'s pure `…Elapsed(asOf:)`.
struct TimerView: View {
    var timer: TrackerTimer
    /// "Reset App": discard the run and return to the startup screen (T-046).
    var onResetApp: () -> Void = {}
    /// "Reset (keep maps)": groundhog/routers reset — clear inventory, keep
    /// maps, start a fresh lap, and resume (T-046).
    var onGroundhogReset: () -> Void = {}

    /// A **stable** refresh anchor, created once. Passing a fresh `Date()` to
    /// `.periodic(from:)` on every re-render re-phases the schedule and makes
    /// the ms display hitch (e.g. when a groundhog reset triggers a big
    /// re-render); a fixed anchor keeps the ticks smooth. The displayed value is
    /// wall-clock accurate regardless (`context.date` → `…Elapsed(asOf:)`).
    @State private var refreshAnchor = Date()
    @State private var confirmingResetApp = false
    @State private var confirmingGroundhog = false

    var body: some View {
        if timer.hasStarted {
            runningTimer
        } else {
            // Before the run: a Go button, so the tracker can be loaded and
            // configured without the clock already ticking.
            Button {
                timer.start()
            } label: {
                Text("Go")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .frame(minWidth: 90)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .help("Start the run timer")
        }
    }

    private var runningTimer: some View {
        TimelineView(.periodic(from: refreshAnchor, by: 0.03)) { context in
            let now = context.date
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .trailing, spacing: 0) {
                    Text(TimerFormatting.hmsMillis(timer.mainElapsed(asOf: now)))
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundStyle(timer.isRunning ? .green : .orange)
                    // The lap line always reserves its height (hidden until a
                    // lap starts), so it appearing doesn't shift the main timer.
                    Text(TimerFormatting.hmsMillis(timer.lapElapsed(asOf: now)))
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.yellow)
                        .opacity(timer.hasLap ? 1 : 0)
                        .help("Lap timer — resets on each groundhog/routers reset; the main timer keeps running")
                }
                controls
            }
        }
        .confirmationDialog("Reset the app?", isPresented: $confirmingResetApp, titleVisibility: .visible) {
            Button("Reset App (discard everything)", role: .destructive, action: onResetApp)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Returns to the startup screen as if you'd just reopened the app. All marks, items, hints, and the timer are discarded. This can't be undone (no save yet).")
        }
        .confirmationDialog("Reset inventory for a groundhog/routers restart?",
                            isPresented: $confirmingGroundhog, titleVisibility: .visible) {
            Button("Reset inventory (keep maps)", role: .destructive, action: onGroundhogReset)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Removes all items, triforces, and take-any hearts so you can replay the same seed. Your overworld marks and known item locations stay, the lap timer restarts, and the run resumes. This can't be undone (no save yet).")
        }
    }

    /// Running → just a Pause button. Paused → the reset hub: Resume plus the
    /// three resets (App / Timer / keep-maps), mirroring the reference's pause
    /// dialog minus its pointless "close & restart the app" option (T-046).
    @ViewBuilder
    private var controls: some View {
        if timer.isRunning {
            Button("Pause") { timer.pause() }
                .font(.caption)
                .controlSize(.small)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Button("Resume") { timer.resume() }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .controlSize(.small)
                    .help("Timer paused — click to resume")
                HStack(spacing: 4) {
                    Button("Reset App") { confirmingResetApp = true }
                        .help("Discard everything and return to the startup screen, as if you'd just reopened the app")
                    Button("Reset Timer") { timer.reset() }
                        .help("Set the timer back to 0:00:00 (keeps your marks and items)")
                    Button("Reset (keep maps)") { confirmingGroundhog = true }
                        .help("Groundhog/routers restart: clear inventory but keep your overworld marks and known item locations")
                }
                .font(.caption)
                .controlSize(.small)
            }
        }
    }
}
