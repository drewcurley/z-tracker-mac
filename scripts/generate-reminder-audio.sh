#!/bin/bash
# Generates the pre-rendered reminder audio clips (T-024).
#   sh scripts/generate-reminder-audio.sh ["Voice Name"]   (default: Zoe Premium)
#
# Uses a single Swift process (generate-reminder-audio.swift) that keeps the
# voice loaded across all clips — essential for neural voices, where each
# separate `say` invocation reloads the model (~60s/clip). Renders CAF via
# AVSpeechSynthesizer.write, then transcodes to m4a (AAC). The clip keys must
# stay in sync with `ReminderAnnouncement.audioKey`.
set -e
DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$DIR/Sources/ZTrackerMac/Resources/audio"
TMP="$(mktemp -d)"
mkdir -p "$OUT"
swiftc -O "$DIR/scripts/generate-reminder-audio.swift" -o "$TMP/gen"
"$TMP/gen" "$TMP"
rm -f "$OUT"/*.m4a
for f in "$TMP"/*.caf; do
  afconvert -f m4af -d aac "$f" "$OUT/$(basename "$f" .caf).m4a"
done
echo "Generated $(ls "$OUT"/*.m4a | wc -l | tr -d ' ') clips -> $OUT"
