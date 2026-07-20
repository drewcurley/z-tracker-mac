import SwiftUI

/// Flip a popover-presentation `@State` flag *without* SwiftUI's fade/expand
/// transition, so the popover snaps in immediately (T-145/T-160). Profiling the
/// dungeon-room pickers showed the open animation — not layout — is the bulk of the
/// perceived ~500 ms open delay; disabling the transaction animation removes it.
/// (AppKit still animates the `NSPopover` frame a little, but this drops the extra
/// SwiftUI layer.) Use it everywhere a click/right-click/VoiceOver action presents a
/// picker popover, so every popover in the app opens with the same snappiness.
@MainActor
func presentPopoverWithoutAnimation(_ present: () -> Void) {
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction, present)
}
