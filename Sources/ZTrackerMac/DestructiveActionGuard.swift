import SwiftUI

/// A state-destructive action pending confirmation (T-051). Because the top
/// section packs many controls close together, a misclick on something that
/// wipes game state (Heart Shuffle / Hidden Dungeon Numbers rebuild the dungeon
/// tracker; Reset Timer zeroes the run) would ruin a run. Once the run has
/// started (Go pressed) — running **or paused**, since misclicks happen either
/// way (T-052) — such actions are routed through a confirmation instead of
/// firing immediately; before the run starts, they apply directly (that's
/// deliberate setup).
struct DestructiveAction: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let confirmLabel: String
    let perform: () -> Void
}

extension View {
    /// Presents a confirmation for the `pending` destructive action (if any).
    func destructiveActionConfirmation(_ pending: Binding<DestructiveAction?>) -> some View {
        confirmationDialog(
            pending.wrappedValue?.title ?? "",
            isPresented: Binding(get: { pending.wrappedValue != nil },
                                 set: { if !$0 { pending.wrappedValue = nil } }),
            titleVisibility: .visible,
            presenting: pending.wrappedValue
        ) { action in
            Button(action.confirmLabel, role: .destructive) {
                action.perform()
                pending.wrappedValue = nil
            }
            Button("Cancel", role: .cancel) { pending.wrappedValue = nil }
        } message: { action in
            Text(action.message)
        }
    }
}

/// Runs `perform` now, or — when `confirmFirst` is true — stashes it into
/// `pending` for confirmation (T-051/T-052). Pure routing helper so the guard
/// decision is consistent across the destructive controls; callers pass the
/// condition (e.g. `timer.hasStarted`).
@MainActor
func runOrConfirm(
    confirmFirst: Bool,
    into pending: inout DestructiveAction?,
    title: String,
    message: String,
    confirmLabel: String,
    perform: @escaping () -> Void
) {
    if confirmFirst {
        pending = DestructiveAction(title: title, message: message, confirmLabel: confirmLabel, perform: perform)
    } else {
        perform()
    }
}
