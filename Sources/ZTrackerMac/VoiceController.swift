import AVFoundation
import Observation
import Speech
import TrackerCore

/// Thread-safe holder so the audio tap (audio render thread) always feeds whatever
/// recognition request the main actor has installed — letting us swap requests between
/// commands **without** reconfiguring the audio graph (which, done on a live engine,
/// races the audio IO thread and crashes). `append` is safe to call off any thread.
private final class RequestBox: @unchecked Sendable {
    private let lock = NSLock()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var appended = 0
    /// How many audio buffers have been fed (diagnostics — proves the mic tap is live).
    var bufferCount: Int { lock.lock(); defer { lock.unlock() }; return appended }
    /// Swap in a new request, finalizing the old one — **all under the lock**, so an
    /// in-flight `append` on the audio thread can never race `endAudio`/dealloc of the
    /// request it's writing to (that race corrupts the heap).
    func swap(to r: SFSpeechAudioBufferRecognitionRequest?) {
        lock.lock(); request?.endAudio(); request = r; lock.unlock()
    }
    /// Called on the audio render thread. `append` happens *inside* the lock so it is
    /// mutually exclusive with `swap`.
    func append(_ buffer: AVAudioPCMBuffer) {
        lock.lock(); request?.append(buffer); appended += 1; lock.unlock()
    }
}

/// File diagnostics for the voice pipeline (T-137). Written to a fixed path so it can
/// be read regardless of how the app was launched (a raw-binary launch bypasses the
/// bundle Info.plist and is TCC-killed, so stderr isn't reliable here).
private let vlogPath = "/tmp/ztracker-voice.log"
private func vlog(_ s: String) {
    guard let data = "[voice] \(s)\n".data(using: .utf8) else { return }
    let url = URL(fileURLWithPath: vlogPath)
    if let fh = try? FileHandle(forWritingTo: url) {
        defer { try? fh.close() }
        fh.seekToEndOfFile()
        fh.write(data)
    } else {
        try? data.write(to: url)
    }
}

/// Hands-free voice control (T-137). On-device `SFSpeechRecognizer` over the mic; each
/// spoken phrase is parsed by `VoiceGrammar` and executed through the same region-apply
/// code the hotkey cursor uses. Toggled from the FLAGS mic button.
///
/// Lifecycle: the audio engine + tap are set up **once** in `start()` and torn down
/// **once** in `stop()`. Between commands only the (cheap) recognition request is
/// swapped. Utterance boundaries are detected with a silence debounce, so you speak a
/// command, pause, and it fires — then a clean request is ready for the next.
///
/// Concurrency: Speech/TCC/audio callbacks fire on background queues, so each is
/// nonisolated (`@Sendable` / async continuation), extracts only `Sendable` values, and
/// hops to the main actor to touch state.
@Observable
@MainActor
final class VoiceController {
    enum Auth: Equatable { case unknown, authorized, denied }

    private let model: TrackerModel
    private let focus: TrackerFocusState
    private let options: TrackerOptions

    private(set) var isListening = false
    private(set) var auth: Auth = .unknown
    private(set) var lastHeard = ""
    private(set) var lastCommand = ""

    @ObservationIgnored private let recognizer = SFSpeechRecognizer()
    @ObservationIgnored private let engine = AVAudioEngine()
    @ObservationIgnored private let box = RequestBox()
    @ObservationIgnored private var request: SFSpeechAudioBufferRecognitionRequest?
    @ObservationIgnored private var task: SFSpeechRecognitionTask?
    @ObservationIgnored private var endTimer: Task<Void, Never>?
    @ObservationIgnored private var diagTimer: Task<Void, Never>?
    @ObservationIgnored private var tapInstalled = false
    /// The last utterance we acted on, to avoid double-firing a command (T-137).
    @ObservationIgnored private var lastProcessed = ""
    /// Guards the restart so `isFinal` + a "no speech" error can't spin up a
    /// thousands-per-second task-churn loop that starves the recognizer.
    @ObservationIgnored private var restarting = false
    /// Bumped each session; a recognition callback whose generation is stale (from a
    /// task we've already superseded/cancelled) is ignored — this kills the 301
    /// "canceled" feedback loop where cancelling the old task restarts everything.
    @ObservationIgnored private var generation = 0

    private let config: VoiceConfig

    init(model: TrackerModel, focus: TrackerFocusState, config: VoiceConfig, options: TrackerOptions) {
        self.model = model
        self.focus = focus
        self.config = config
        self.options = options
    }

    func toggle() {
        if isListening { stop() } else { requestAuthThenStart() }
    }

    // MARK: Permissions (off the main actor, then hop back)

    private func requestAuthThenStart() {
        Task {
            let speechOK = await Self.requestSpeechAuth()
            let micOK = speechOK ? await AVCaptureDevice.requestAccess(for: .audio) : false
            auth = (speechOK && micOK) ? .authorized : .denied
            if speechOK && micOK { start() }
        }
    }

    private nonisolated static func requestSpeechAuth() async -> Bool {
        await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0 == .authorized) }
        }
    }

    // MARK: Engine lifecycle — set up / torn down ONCE

    private func start() {
        guard !isListening, let recognizer, recognizer.isAvailable else {
            vlog("start aborted: recognizer available=\(recognizer?.isAvailable ?? false)")
            return
        }
        try? "".write(toFile: vlogPath, atomically: true, encoding: .utf8)   // fresh log
        do {
            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            vlog("input format: \(format.sampleRate)Hz \(format.channelCount)ch; onDevice=\(recognizer.supportsOnDeviceRecognition)")
            if format.sampleRate == 0 || format.channelCount == 0 {
                vlog("⚠️ invalid input format — no usable mic device")
            }
            if !tapInstalled {
                let box = self.box
                input.installTap(onBus: 0, bufferSize: 1024, format: format) { @Sendable buffer, _ in
                    box.append(buffer)
                }
                tapInstalled = true
            }
            engine.prepare()
            try engine.start()
            isListening = true
            startDiag()
            startSession()
        } catch {
            lastCommand = "mic error"
            stop()
        }
    }

    func stop() {
        endTimer?.cancel(); endTimer = nil
        diagTimer?.cancel(); diagTimer = nil
        task?.cancel(); task = nil
        box.swap(to: nil)   // finalizes + clears the request under the lock
        request = nil
        if engine.isRunning { engine.stop() }
        if tapInstalled { engine.inputNode.removeTap(onBus: 0); tapInstalled = false }
        isListening = false
        restarting = false
        lastHeard = ""
    }

    /// Restart the recognition session after a short beat — **guarded** so overlapping
    /// end signals (isFinal, "no speech" error, fallback) collapse into one restart,
    /// and **delayed** so we never busy-loop creating tasks the recognizer can't serve.
    private func restart() {
        guard isListening, !restarting else { return }
        restarting = true
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(150))
            guard let self, self.isListening else { self?.restarting = false; return }
            self.restarting = false
            self.startSession()
        }
    }

    /// Begin **one** recognition task for the session. It runs continuously; commands
    /// are pulled from its growing transcript on each pause (`processNewTail`). We only
    /// come back here when the task naturally ends (its ~1-minute limit or an error) —
    /// never per command, which is what wedged the recognizer before. Only the request
    /// is swapped; the audio engine/tap are left running.
    private func startSession() {
        guard isListening else { return }
        endTimer?.cancel(); endTimer = nil
        generation &+= 1
        let gen = generation
        task?.cancel(); task = nil        // its stale callback is ignored via `gen`
        lastHeard = ""
        lastProcessed = ""

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        req.requiresOnDeviceRecognition = true
        req.contextualStrings = VoiceGrammar.contextualVocabulary(config)   // bias toward jargon
        request = req
        box.swap(to: req)   // finalizes the previous request under the lock, atomically

        let started = Date()
        vlog("session \(gen) started")
        task = recognizer?.recognitionTask(with: req) { @Sendable result, error in
            let transcript = result?.bestTranscription.formattedString
            let isFinal = result?.isFinal ?? false
            let errCode = (error as NSError?)?.code
            Task { @MainActor [weak self] in
                // Ignore callbacks from a task we've already replaced.
                guard let self, self.isListening, gen == self.generation else { return }
                if let transcript { self.heard(transcript, isFinal: isFinal) }
                if let errCode {
                    let ms = Int(Date().timeIntervalSince(started) * 1000)
                    // Code 1110 = "no speech detected": a silent window, normal between
                    // commands — not a failure. Any end reason ends the task; open a
                    // fresh one. (ms tells us if the task actually listened.)
                    vlog("session \(gen) ended \(errCode == 1110 ? "no-speech" : "err \(errCode)") after \(ms)ms")
                    self.restart()
                }
            }
        }
    }

    /// Log every second whether audio buffers are flowing — the fast way to tell
    /// "deaf" (0 buffers = mic/tap problem) from "heard-but-didn't-parse".
    private func startDiag() {
        diagTimer?.cancel()
        diagTimer = Task { @MainActor [weak self] in
            var last = 0
            while !Task.isCancelled, let self, self.isListening {
                let n = self.box.bufferCount
                vlog("buffers=\(n) (+\(n - last)/s)  heard=\"\(self.lastHeard)\"")
                last = n
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    // MARK: Utterance handling

    /// A recognition result arrived. The recognizer finalizes each spoken phrase
    /// (`isFinal`) — that's the natural command boundary, so act on it and start the
    /// next session. A change-based fallback timer covers the rare phrase that never
    /// finalizes (only re-armed when the transcript actually *changes*, so a repeated
    /// partial can't keep it from firing).
    private func heard(_ transcript: String, isFinal: Bool) {
        if transcript != lastHeard {
            lastHeard = transcript
            armFallback()
        }
        if isFinal {
            processUtterance(transcript)
            restart()
        }
    }

    /// ~0.5s after the transcript stops changing, act — faster than waiting for the
    /// recognizer's own (slow) end-of-speech, and re-armed only on a real change so a
    /// repeated partial can't keep it from firing.
    private func armFallback() {
        endTimer?.cancel()
        endTimer = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled, let self, self.isListening else { return }
            let text = self.lastHeard
            self.processUtterance(text)
            self.restart()
        }
    }

    /// Parse and run one finalized phrase (deduped so `isFinal` + fallback can't both
    /// fire it).
    private func processUtterance(_ text: String) {
        endTimer?.cancel(); endTimer = nil
        let phrase = text.trimmingCharacters(in: .whitespaces)
        guard !phrase.isEmpty, phrase != lastProcessed else { return }
        lastProcessed = phrase
        if let command = VoiceGrammar.parse(phrase, config: config) {
            vlog("utterance=\"\(phrase)\" → \(command)")
            execute(command)
            lastCommand = describe(command)
        } else {
            vlog("utterance=\"\(phrase)\" → (no command)")
        }
    }

    // MARK: Execute

    private func execute(_ command: VoiceCommand) {
        switch command {
        case let .moveCursor(dcol, drow):
            focus.moveCursor(dcol: dcol, drow: drow)
        case let .cursorTo(column, row):
            focus.setCursor(col: column, row: row)
        case let .actionAtCursor(words):
            applyAction(words)
        case let .actionAt(column, row, words):
            focus.setCursor(col: column, row: row)
            applyAction(words)
        case let .dungeonTab(n):
            focus.selectedDungeonTab = n - 1
            focus.cursorRegion = .dungeonMap        // drop the cursor into that dungeon
            focus.cursorShown = true
            // If this dungeon already has an entrance marked, jump the cursor there.
            if let cell = dungeonEntranceCell() { focus.setCursor(col: cell.col, row: cell.row) }
        case .exitToOverworld:
            // Leaving a dungeon lands on that dungeon's marker on the overworld map.
            let dungeonNumber = focus.cursorRegion == .dungeonMap ? focus.selectedDungeonTab + 1 : nil
            focus.cursorRegion = .overworld
            focus.cursorShown = true
            if let n = dungeonNumber, let cell = overworldDungeonMarker(n) {
                focus.setCursor(col: cell.col, row: cell.row)
            }
        case .gotoStart:
            // Contextual: in a dungeon → its entrance; on the overworld → the start tile.
            if focus.cursorRegion == .dungeonMap {
                if let cell = dungeonEntranceCell() { focus.setCursor(col: cell.col, row: cell.row) }
            } else if let s = model.startSpot {
                focus.cursorRegion = .overworld
                focus.setCursor(col: s.x, row: s.y)
            }
        case let .toggleProgression(id):
            applyProgression(id)
        case let .setItemBox(boxID, itemID):
            if !ItemBoxVoiceApply.apply(boxID: boxID, itemID: itemID, region: focus.cursorRegion,
                                        tracker: model.dungeonTracker) {
                vlog("item box \(boxID)=\(itemID) not applied (region \(focus.cursorRegion), or item can't go here)")
            }
        case .stopListening:
            vlog("stop listening (voice command)")
            stop()
        case let .clearAtCursor(words):
            applyClear(words, cell: focus.cursorCell)
        case let .clearAt(column, row, words):
            focus.setCursor(col: column, row: row)
            applyClear(words, cell: focus.cursorCell)
        }
    }

    /// Un-mark / clear (T-149) — region-aware. Empty `words` = clear the cursor cell
    /// (overworld) or room (dungeon); otherwise clear the named target.
    private func applyClear(_ words: [String], cell: TrackerFocusState.GridCell) {
        switch focus.cursorRegion {
        case .overworld:
            if clearProgression(words) { return }   // "un-take wood sword" from the overworld
            OverworldMark.apply(.unmarked, column: cell.col, row: cell.row, grid: model.overworldGrid,
                                releaseTakeAny: { c, r in model.releaseOverworldTakeAny(column: c, row: r) },
                                placeDungeon: { _, _, _ in })
        case .dungeonMap:
            applyDungeonClear(words, cell: cell)
        case .blockers:
            // A slot holds one blocker, so any clear here empties the slot (T-159).
            let t = BlockerRegion.target(cell)
            model.dungeonBlockers.setDungeonBlocker(.nothing, dungeon: t.dungeon, slot: t.slot)
        default:
            // .items / .dungeonItem — the only generic clear is a progression flag
            // ("un-take wood sword").
            _ = clearProgression(words)
        }
    }

    /// Clear a progression flag if the words name one. Returns whether it did.
    @discardableResult
    private func clearProgression(_ words: [String]) -> Bool {
        guard let m = config.match(words, scope: .progression) else { return false }
        return ProgressionVoiceApply.apply(id: m.actionID, region: focus.cursorRegion,
                                           progress: model.playerProgress, value: false)
    }

    /// Clear a dungeon target: door(s) by direction, a room type / monster / floor
    /// drop by name, or — with no target — the whole room.
    private func applyDungeonClear(_ words: [String], cell: TrackerFocusState.GridCell) {
        let tab = focus.selectedDungeonTab
        guard (0..<model.dungeonRoomMaps.count).contains(tab) else { return }
        let map = model.dungeonRoomMaps[tab]
        let actions = VoiceGrammar.dungeonClearActions(words, config: config)
        if actions.isEmpty {
            // Generic "clear this room" — wipe type, monsters, and floor drop.
            DungeonRoomMark.applyRoomType(.unmarked, col: cell.col, row: cell.row, map: map, inferDoors: false)
            var r = map.room(col: cell.col, row: cell.row)
            r.floorDropDetail = .unmarked
            while let m = r.monsters.first { r.toggleMonster(m) }
            _ = map.setRoom(r, col: cell.col, row: cell.row)
            return
        }
        for a in actions {
            switch a {
            case .roomType, .entrance:
                DungeonRoomMark.applyRoomType(.unmarked, col: cell.col, row: cell.row, map: map, inferDoors: false)
            case .floorDrop:
                DungeonRoomMark.setFloorDrop(.unmarked, col: cell.col, row: cell.row, map: map)
            case .monster(let m):
                if map.room(col: cell.col, row: cell.row).monsters.contains(m) {
                    DungeonRoomMark.toggleMonster(m, col: cell.col, row: cell.row, map: map)
                }
            case let .door(_, dir):
                setDungeonDoor(.unknown, dir, col: cell.col, row: cell.row, map: map)
            }
        }
    }

    /// Flag a player-progress item as acquired (T-142); region-scoping + mapping live in
    /// the pure `ProgressionVoiceApply` helper so voice and tests share one path.
    private func applyProgression(_ id: String) {
        if !ProgressionVoiceApply.apply(id: id, region: focus.cursorRegion, progress: model.playerProgress) {
            vlog("progression \(id) not applied (unknown, or overworld-scoped — say it while viewing the overworld)")
        }
    }

    /// The entrance room (a `startEnterFrom*`) of the currently-selected dungeon, if any.
    private func dungeonEntranceCell() -> TrackerFocusState.GridCell? {
        let tab = focus.selectedDungeonTab
        guard (0..<model.dungeonRoomMaps.count).contains(tab) else { return nil }
        let map = model.dungeonRoomMaps[tab]
        for row in 0..<DungeonRoomMap.rows {
            for col in 0..<DungeonRoomMap.cols where map.room(col: col, row: row).roomType.isEntrance {
                return .init(col: col, row: row)
            }
        }
        return nil
    }

    /// The overworld tile marked as dungeon `n` (1–9), if any.
    private func overworldDungeonMarker(_ n: Int) -> TrackerFocusState.GridCell? {
        let grid = model.overworldGrid
        for row in 0..<OverworldGrid.rowCount {
            for col in 0..<OverworldGrid.columnCount {
                if case .dungeon(let d) = grid.mark(column: col, row: row), d == n {
                    return .init(col: col, row: row)
                }
            }
        }
        return nil
    }

    /// Apply action words at the current cursor cell, interpreted for the active
    /// region. Overworld is wired; the other regions come as their vocabularies land.
    private func applyAction(_ words: [String]) {
        let cell = focus.cursorCell
        switch focus.cursorRegion {
        case .overworld:
            guard !model.isDeadSpot(x: cell.col, y: cell.row) else { return }
            // Two distinct shop items named in one utterance set the primary shop mark
            // *and* the tile's second item together (T-158) — no need for two commands.
            if let pair = VoiceGrammar.overworldShopPair(words, config: config) {
                OverworldMark.apply(.shop(pair.primary), column: cell.col, row: cell.row,
                                    grid: model.overworldGrid,
                                    releaseTakeAny: { c, r in model.releaseOverworldTakeAny(column: c, row: r) },
                                    placeDungeon: { _, _, _ in })
                model.overworldGrid.setShopSecondItem(pair.second, column: cell.col, row: cell.row)
                return
            }
            guard let action = VoiceGrammar.overworldAction(words, config: config) else {
                vlog("no overworld action in \(words)"); return
            }
            switch action {
            case .mark(let mark):
                // A second shop word on an existing shop tile sets the tile's *second*
                // item rather than overwriting the primary (T-141).
                if OverworldMark.applyVoiceSecondShopItem(mark, column: cell.col, row: cell.row,
                                                          grid: model.overworldGrid) { return }
                OverworldMark.apply(mark, column: cell.col, row: cell.row, grid: model.overworldGrid,
                                    releaseTakeAny: { c, r in model.releaseOverworldTakeAny(column: c, row: r) },
                                    placeDungeon: { number, c, r in
                                        OverworldMark.didPlaceDungeon(number, column: c, row: r, model: model, focus: focus)
                                    })
            case .takeAny(let state):
                model.setOverworldTakeAny(state, column: cell.col, row: cell.row)
            case .setStart:
                model.startSpot = OverworldScreenCoordinate(x: cell.col, y: cell.row)
            case .clearStart:
                model.startSpot = nil
            }
        case .dungeonMap:
            applyDungeonAction(words, cell: cell)
        case .blockers:
            guard let blocker = VoiceGrammar.blockerAction(words, config: config) else {
                vlog("no blocker action in \(words)"); return
            }
            let t = BlockerRegion.target(cell)
            model.dungeonBlockers.setDungeonBlocker(blocker, dungeon: t.dungeon, slot: t.slot)
        default:
            vlog("voice action in region \(focus.cursorRegion) not supported yet: \(words)")
        }
    }

    /// Apply dungeon-region action words at `cell` for the selected dungeon: room
    /// type / monster / floor drop, or one-or-more door commands, or an entrance.
    private func applyDungeonAction(_ words: [String], cell: TrackerFocusState.GridCell) {
        let tab = focus.selectedDungeonTab
        guard (0..<model.dungeonRoomMaps.count).contains(tab) else { return }
        let map = model.dungeonRoomMaps[tab]
        let actions = VoiceGrammar.dungeonActions(words, config: config)
        if actions.isEmpty { vlog("no dungeon action in \(words)"); return }
        for action in actions {
            switch action {
            case .roomType(let type):
                DungeonRoomMark.applyRoomType(type, col: cell.col, row: cell.row, map: map,
                                              inferDoors: options.doDoorInference)
            case .monster(let monster):
                DungeonRoomMark.toggleMonster(monster, col: cell.col, row: cell.row, map: map)
            case .floorDrop(let drop):
                DungeonRoomMark.setFloorDrop(drop, col: cell.col, row: cell.row, map: map)
            case let .door(state, dir):
                setDungeonDoor(state, dir, col: cell.col, row: cell.row, map: map)
            case .entrance(let dir):
                let type: RoomType = switch dir {
                case .north: .startEnterFromN; case .south: .startEnterFromS
                case .east: .startEnterFromE; case .west: .startEnterFromW
                }
                DungeonRoomMark.applyRoomType(type, col: cell.col, row: cell.row, map: map,
                                              inferDoors: options.doDoorInference)
            }
        }
    }

    /// The door on the `dir` side of room `(col,row)`, guarding grid edges (there is
    /// no door beyond the outer wall).
    private func setDungeonDoor(_ state: DoorState, _ dir: VoiceGrammar.VoiceDirection,
                                col: Int, row: Int, map: DungeonRoomMap) {
        switch dir {
        case .east:  if col < DungeonRoomMap.cols - 1 { map.setHorizontalDoor(state, col: col, row: row) }
        case .west:  if col > 0 { map.setHorizontalDoor(state, col: col - 1, row: row) }
        case .south: if row < DungeonRoomMap.rows - 1 { map.setVerticalDoor(state, col: col, row: row) }
        case .north: if row > 0 { map.setVerticalDoor(state, col: col, row: row - 1) }
        }
    }

    private func describe(_ command: VoiceCommand) -> String {
        switch command {
        case .moveCursor: return "move"
        case let .cursorTo(c, r): return OverworldCoords.label(column: c, row: r)
        case .actionAtCursor: return "mark"
        case let .actionAt(c, r, _): return "\(OverworldCoords.label(column: c, row: r)) mark"
        case let .dungeonTab(n): return "Level \(n)"
        case .exitToOverworld: return "overworld"
        case .gotoStart: return "→ start"
        case let .toggleProgression(id): return ProgressionVoiceApply.toggle(forID: id)?.help ?? "item"
        case let .setItemBox(boxID, _): return ItemBoxVoiceApply.box(forID: boxID)?.help ?? "item box"
        case let .clearAtCursor(words): return words.isEmpty ? "clear" : "clear \(words.joined(separator: " "))"
        case let .clearAt(c, r, _): return "\(OverworldCoords.label(column: c, row: r)) clear"
        case .stopListening: return "⏸ voice"
        }
    }
}
