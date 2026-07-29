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
        // The weapon "bow" (/boʊ/) — voices otherwise read it as "bow" (/baʊ/, bending
        // over), e.g. "get the bow off the coast". "beau" gets the right vowel. Whole
        // word only, so "elbow"/"rainbow" are untouched.
        s = s.replacingOccurrences(of: "\\bbow\\b", with: "beau",
                                   options: [.regularExpression, .caseInsensitive])
        return s
    }
}
