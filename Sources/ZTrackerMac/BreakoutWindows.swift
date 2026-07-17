import Observation

/// Tracks which "break-out" areas are currently open in their own window (T-100).
/// App-level state shared between the inline sections (which show a placeholder
/// while their content is popped out) and the window scenes (whose appear/disappear
/// toggles these flags). The first area is the Timeline; the pattern extends to the
/// other major areas later.
@Observable
@MainActor
final class BreakoutWindows {
    /// The Timeline is showing in its own window (so the inline section is a
    /// placeholder until the window closes).
    var timelinePoppedOut = false
}
