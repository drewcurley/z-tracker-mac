import AppKit
import TrackerCore

/// Short audible confirmation cues (T-208). Two independent channels, each gated by its own
/// setting:
///
/// * **voice** — plays when a spoken command is recognized (`voiceConfirmationSound`, on by
///   default). You can't see the mic register, so the cue confirms the command landed.
/// * **input** — plays when a tracker edit is made by mouse or keyboard (`inputConfirmationSound`,
///   off by default). Opt-in, since the map already gives visual feedback.
///
/// The sounds are the **original Windows Z-Tracker files** (reference `Graphics.fs`): the voice
/// cue is `confirm_speech.wav` (its `PlaySoundForSpeechRecognizedAndUsedToMark`), and the input
/// tick reuses `reminder_clink.wav` (a short clink) so the two apps sound alike. Loaded once and
/// restarted on each play (~0.5s, so a rapid burst of edits re-triggers rather than overlapping).
@MainActor
enum ConfirmationSound {
    /// The recognized-voice-command cue — the reference's `confirm_speech.wav`.
    private static let voiceCue = load("confirm_speech")
    /// The mouse/keyboard tick — the reference's `reminder_clink.wav`.
    private static let inputCue = load("reminder_clink")

    private static func load(_ name: String) -> NSSound? {
        guard let url = AppResources.url(forResource: name, withExtension: "wav") else { return nil }
        return NSSound(contentsOf: url, byReference: true)
    }

    /// Force both sounds to load at launch. The reference notes the *first* play lags the system,
    /// so it primes at startup (`WPFUI.fs`); touching the lazy statics here does the same.
    static func warmUp() { _ = voiceCue; _ = inputCue }

    /// Play the voice-command cue when `voiceConfirmationSound` is on, at its own volume.
    static func voice(_ options: TrackerOptions) {
        guard options.voiceConfirmationSound else { return }
        play(voiceCue, volume: options.voiceConfirmationVolume)
    }

    /// Play the mouse/keyboard tick when `inputConfirmationSound` is on, at its own volume.
    static func input(_ options: TrackerOptions) {
        input(enabled: options.inputConfirmationSound, volume: options.inputConfirmationVolume)
    }

    /// Value-driven variant for views that receive only the extracted flag + volume (not the
    /// whole `TrackerOptions`), matching how `inferDoors` / `preferNonDescript` are threaded.
    static func input(enabled: Bool, volume: Int) {
        guard enabled else { return }
        play(inputCue, volume: volume)
    }

    private static func play(_ sound: NSSound?, volume: Int) {
        guard let sound, volume > 0 else { return }
        if sound.isPlaying { sound.stop() }   // restart so back-to-back edits each tick
        sound.volume = Float(max(0, min(100, volume))) / 100   // 0…100 → 0.0…1.0
        sound.play()
    }
}
