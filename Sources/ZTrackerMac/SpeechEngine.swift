import AVFoundation
import TrackerCore

/// The single live text-to-speech engine for spoken reminders (T-069).
///
/// Reminders were pre-rendered `m4a` clips (T-024) to dodge `AVSpeechSynthesizer`'s
/// cold-start lag. Now that the audio stack is warmed at launch (T-045) and the
/// synth is primed here too, live TTS is instant — so we speak dynamically with
/// the natural **Zoe (Premium)** voice, dropping the clip pipeline entirely and
/// gaining any-text reminders.
///
/// One shared `AVSpeechSynthesizer` is the whole design: it **queues utterances
/// internally**, so two reminders from one action speak back-to-back instead of
/// overlapping (the T-068 bug) — no separate serial queue needed.
@MainActor
enum SpeechEngine {
    /// The one synthesizer. Shared so every utterance goes through the same
    /// internal queue (no cross-overlap) and reuses the already-loaded voice.
    private static let synthesizer = AVSpeechSynthesizer()

    /// The voice to speak with: the user's chosen voice if set and still present,
    /// else **Zoe (Premium)**, else the system default (`nil`) if Zoe isn't
    /// installed.
    static func voice(preferredIdentifier: String?) -> AVSpeechSynthesisVoice? {
        if let preferredIdentifier, let v = AVSpeechSynthesisVoice(identifier: preferredIdentifier) {
            return v
        }
        let voices = AVSpeechSynthesisVoice.speechVoices()
        return voices.first { $0.name == "Zoe" && $0.quality == .premium }
            ?? voices.first { $0.name.contains("Zoe") }
    }

    /// Speak `text` (rewritten for correct pronunciation, T-086) at `volume`
    /// (0…1). Queued behind anything already speaking.
    static func speak(_ text: String, volume: Float, preferredVoiceIdentifier: String?) {
        let utterance = AVSpeechUtterance(string: SpeechText.spoken(text))
        utterance.volume = max(0, min(1, volume))
        utterance.voice = voice(preferredIdentifier: preferredVoiceIdentifier)
        synthesizer.speak(utterance)
    }

    /// Prime the speech service, voice model, and audio output stack at launch by
    /// speaking a silent space, so the first real reminder is instant (the T-069
    /// mitigation for `AVSpeechSynthesizer` first-use lag). Uses the same shared
    /// synthesizer and resolved voice the reminders will use.
    static func warmUp(preferredVoiceIdentifier: String?) {
        let utterance = AVSpeechUtterance(string: " ")
        utterance.volume = 0
        utterance.voice = voice(preferredIdentifier: preferredVoiceIdentifier)
        synthesizer.speak(utterance)
    }
}
