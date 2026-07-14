import AVFoundation
import Foundation

let clips: [(String, String)] = [
    ("consider_sword2", "Consider getting the white sword item"),
    ("consider_sword3", "Consider the magical sword"),
    ("dungeon_complete_1","Dungeon 1 is complete"),("dungeon_complete_2","Dungeon 2 is complete"),
    ("dungeon_complete_3","Dungeon 3 is complete"),("dungeon_complete_4","Dungeon 4 is complete"),
    ("dungeon_complete_5","Dungeon 5 is complete"),("dungeon_complete_6","Dungeon 6 is complete"),
    ("dungeon_complete_7","Dungeon 7 is complete"),("dungeon_complete_8","Dungeon 8 is complete"),
    ("dungeon_complete_9","Dungeon 9 is complete"),
    ("located_1","You have located one dungeon"),("located_2","You have located 2 dungeons"),
    ("located_3","You have located 3 dungeons"),("located_4","You have located 4 dungeons"),
    ("located_5","You have located 5 dungeons"),("located_6","You have located 6 dungeons"),
    ("located_7","You have located 7 dungeons"),("located_8","You have located 8 dungeons"),
    ("located_9","Congratulations, you have located all nine dungeons"),
    ("triforce_1","You now have one triforce"),("triforce_2","You now have 2 triforces"),
    ("triforce_3","You now have 3 triforces"),("triforce_4","You now have 4 triforces"),
    ("triforce_5","You now have 5 triforces"),("triforce_6","You now have 6 triforces"),
    ("triforce_7","You now have 7 triforces"),("triforce_8","You now have 8 triforces"),
    ("tag_might","You might be triforce and go"),("tag_probably","You are probably triforce and go"),
    ("tag_go","You are triforce and go"),("tag_need","You need something to be triforce and go"),
    ("unblock_ladder","You can revisit a dungeon, now that you have the ladder"),
    ("unblock_recorder","You can revisit a dungeon, now that you have the recorder"),
    ("unblock_bow","You can revisit a dungeon, now that you have the bow and arrow"),
    ("unblock_key","You can revisit a dungeon, now that you have the magic key"),
    ("unblock_bomb","You can revisit a dungeon, now that you have bombs"),
    ("unblock_combat","You can revisit a dungeon, now that you have a better weapon or armor"),
    ("have_ladder","Don't forget that you have the ladder"),
    ("have_key","Don't forget that you have the any key"),
]
let outDir = CommandLine.arguments[1]
guard let voice = AVSpeechSynthesisVoice.speechVoices().first(where: { $0.name == "Zoe" && $0.quality == .premium })
    ?? AVSpeechSynthesisVoice.speechVoices().first(where: { $0.name.contains("Zoe") }) else {
    FileHandle.standardError.write("Zoe not found\n".data(using: .utf8)!); exit(1)
}
let synth = AVSpeechSynthesizer()
var index = 0
func renderNext() {
    if index >= clips.count { CFRunLoopStop(CFRunLoopGetMain()); return }
    let (key, text) = clips[index]; index += 1
    let utt = AVSpeechUtterance(string: text); utt.voice = voice
    var file: AVAudioFile? = nil
    synth.write(utt) { buffer in
        guard let pcm = buffer as? AVAudioPCMBuffer else { return }
        if pcm.frameLength == 0 {
            print("rendered \(key)"); fflush(stdout)
            DispatchQueue.main.async { renderNext() }
            return
        }
        if file == nil { file = try? AVAudioFile(forWriting: URL(fileURLWithPath: "\(outDir)/\(key).caf"), settings: pcm.format.settings) }
        try? file?.write(from: pcm)
    }
}
DispatchQueue.main.async { renderNext() }
CFRunLoopRun()
