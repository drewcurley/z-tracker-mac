/// Text-to-speech pronunciation fixups (T-086). The reminder engine's *display*
/// text uses the real spellings; this rewrites a string into the form we hand to
/// the voice engine so it says certain words correctly.
///
/// "Triforce" is the notable one — voices read it as "triff-orss"; spelling it
/// "try force" / "try forces" for the synthesizer gets the right pronunciation.
/// Applied both at runtime (live TTS fallback) and when pre-rendering the clips,
/// so the two paths sound identical.
public enum SpeechText {
    /// The spoken form of `text`: display spellings rewritten for the voice engine.
    public static func spoken(_ text: String) -> String {
        var s = text
        // Plural before singular so "triforces" isn't half-replaced. Case-
        // insensitive, preserving surrounding text.
        for (from, to) in [("triforces", "try forces"), ("triforce", "try force")] {
            s = s.replacingOccurrences(of: from, with: to, options: .caseInsensitive)
        }
        return s
    }
}
