import CoreGraphics
import SwiftUI
import TrackerCore

/// The overworld map (docs/domain.md § 4.5, T-006 core data model +
/// interaction, T-007 tile-mark sprite rendering, T-008 terrain background).
/// Renders the reference app's actual terrain art
/// (`s_map_overworld_vanilla_strip8.png`, per selected quest, via
/// `OverworldBackgroundAtlas`) as the base layer, with tile-mark icons
/// (`s_icon_overworld_strip39.png`, via `OverworldIconAtlas`) composited on
/// top wherever a mark is set. Both assets are MIT-licensed — see
/// `/NOTICE.md`.
///
/// Confirmed gestures implemented: left-click an unmarked tile marks it
/// `.dontCare` ("dark"); left-click a `.dontCare` tile, or right-click any
/// tile, opens a mark-selection menu. The reference app's actual popup UI
/// shape (a custom grid-of-icons picker) is a follow-up — a context menu is
/// this task's functional stand-in, not a guess at the real design.
struct OverworldMapView: View {
    var grid: OverworldGrid
    var quest: OverworldQuest
    var options: TrackerOptions

    /// Live derived player state (T-014). Supplies real ladder/raft
    /// possession to the routing graph below, replacing T-011's documented
    /// placeholders.
    var playerState: PlayerComputedStateSummary

    /// Live derived overworld map state (T-015.3). Supplies
    /// `owGettableLocations` for the true green/yellow/red highlight cascade
    /// (T-015.4), replacing T-011's flat single-color "reachable" overlay.
    var mapState: MapStateSummary

    /// Top-section map-overlay toggles (T-035.2). `nil` = no overlays.
    var overlays: OverworldOverlayState?
    /// Whether the Armos item has been recorded (gates the late-game open-caves
    /// overlay); supplied by the parent from `dungeonTracker.armosBox`.
    var armosClaimed: Bool = false

    /// Whether the overworld is mirrored East↔West (T-047). Flips the whole map
    /// horizontally (`scaleEffect(x: -1)`), so a tap on the visually-left screen
    /// still edits its true (mirrored) data column — no coordinate remap needed.
    /// Readable glyphs (dungeon numerals, interior icons, fairy, coords) are
    /// counter-flipped so they don't render backwards, matching the reference's
    /// re-flip of `mirrorOverworldFEs` (`UI.fs:1302-1310`).
    var mirrored: Bool = false

    /// Hidden Dungeon Numbers (T-049): dungeon marks are labeled A–H (1–8)
    /// instead of numbers, both in the tile selector and on the map (Level 9
    /// stays "9").
    var hideDungeonNumbers: Bool = false

    /// Whether the dungeon in slot `1…9` is 100% complete (all items +
    /// triforce, `Dungeon.isComplete`) — its overworld badge dims to dark
    /// yellow (T-035.6), matching the reference's completed-dungeon shading.
    var dungeonComplete: (Int) -> Bool = { _ in false }

    /// The single **current** recorder-warp destination (T-035.7) — the screen
    /// the whistle would take you to right now, per the stepper below the map.
    /// Gets a lone diamond marker; `nil` when there's no valid destination.
    var recorderDestination: OverworldScreenCoordinate? = nil

    /// The player's start screen (T-035.8) — a lime/violet ring marker; `nil`
    /// when unset. Set/cleared from the tile context menu.
    var startSpot: OverworldScreenCoordinate? = nil
    var onSetStartSpot: (Int, Int) -> Void = { _, _ in }
    var onClearStartSpot: () -> Void = {}

    /// Mark a take-any tile with what was taken, syncing its linked Items-group
    /// heart slot (T-066). `(state, column, row)`.
    var onSetTakeAny: (TakeAnyHeartState, Int, Int) -> Void = { _, _, _ in }
    /// Left-click a take-any tile to cycle its claimed state, keeping its slot
    /// in sync (T-066). `(column, row)`.
    var onCycleTakeAny: (Int, Int) -> Void = { _, _ in }
    /// Free a take-any tile's linked slot when the tile is changed to another
    /// mark or cleared (T-066). `(column, row)`.
    var onReleaseTakeAny: (Int, Int) -> Void = { _, _ in }

    /// A dungeon marker was placed (T-039.1) — the parent auto-sets that
    /// dungeon's location hint to the screen's region. `(number, column, row)`.
    var onPlaceDungeon: (Int, Int, Int) -> Void = { _, _, _ in }

    /// Whether any active top-section overlay highlights this tile (T-035.2).
    private func overlayHighlights(column: Int, row: Int, mark: OverworldTileMark) -> Bool {
        guard let overlays else { return false }
        if overlays.isActive(.money), OverworldOverlays.isMoneyTile(mark, secretValue: 0) {
            return true
        }
        if overlays.isActive(.openCaves) {
            let pastEarly = OverworldOverlays.openCavesPastEarlyGame(
                woodSwordCaveFound: mapState.woodSwordCaveFound,
                swordLevel: playerState.swordLevel, candleLevel: playerState.candleLevel)
            return OverworldOverlays.isOpenCaveTile(
                mark: mark,
                nothingable: overworldInstance.nothingable(x: column, y: row),
                hasArmos: overworldInstance.hasArmos(x: column, y: row),
                pastEarlyGame: pastEarly, armosClaimed: armosClaimed)
        }
        return false
    }

    /// The tile-selector label for a sword *cave* (a location). Relabeled from
    /// "Sword cave N" (user request). These are **not** annotated for swordless:
    /// the "White Sword Item" cave holds a *random* item, and it is the white-
    /// sword *weapon* (`ITEMS.whiteSword`, a shuffled box item) — not the cave —
    /// that the bomb upgrade replaces. The weapon's swap is rendered on the
    /// item boxes/picker, not here.
    nonisolated static func swordCaveLabel(_ number: Int) -> String {
        switch number {
        case 1: return "Wood Sword"
        case 2: return "White Sword Item"
        case 3: return "Magical Sword"
        default: return "Sword cave \(number)"
        }
    }

    /// Aspect ratio matches the reference app's base tile shape (16×11px,
    /// `Graphics.fs` `OMTW`/`OMTH` — resolves a previously-open question in
    /// `docs/domain.md` about the layout's numeric constants) — kept even
    /// though this view doesn't render the real sprites yet, so later sprite
    /// integration doesn't have to fight a mismatched grid shape.
    private let tileAspectRatio: CGFloat = 16.0 / 11.0

    @State private var hoveredVertex: OverworldVertex?
    @State private var routeHighlight: OverworldRouteHighlight?

    /// Ladder and raft are live (`playerState.haveLadder`/`.haveRaft`, T-014)
    /// and any-roads are live (T-015.5). The mirror-overworld toggle
    /// (`MirrorOverworld`) is a full display-flip feature (flips the whole
    /// map's marks + background, not just routing) — split out as its own
    /// task (T-015.7), so it stays a documented placeholder here, not
    /// silently hardcoded. `RoutesCanScreenScroll` is already wired to a real
    /// option below.
    private static let placeholderIsMirror = false

    /// Bold/pale highlight cap, matching the reference app's `MaxGYR`
    /// default (`OverworldRouteDrawing.fs:94`/`:28`).
    private static let maxGYR = 12

    /// The marked any-road (warp) screens, from live map state (T-015.5).
    /// Two or more marked any-roads warp between each other in the routing
    /// graph (cost 4), so hover routing can use them.
    private var anyRoadDestinations: [(x: Int, y: Int)] {
        mapState.anyRoadLocations.compactMap { $0 }.map { (x: $0.x, y: $0.y) }
    }

    private var dynamicGraph: OverworldDynamicGraph? {
        OverworldRoutingGraph.dynamicGraph(
            ladder: playerState.haveLadder,
            raft: playerState.haveRaft,
            // Recorder-warp destinations depend on the recorder-dest
            // derivation (recorder options + HDN + the T-018 orchestration),
            // not yet ported — see docs/domain.md § 6 (T-015 follow-ons).
            recorderWarpDestinations: [],
            anyRoads: anyRoadDestinations,
            isMirror: Self.placeholderIsMirror,
            canScreenScroll: options.showScreenScrolls
        )
    }

    private var highlightByCoordinate: [OverworldScreenCoordinate: Bool] {
        guard let routeHighlight else { return [:] }
        return Dictionary(uniqueKeysWithValues: routeHighlight.highlightedTiles.map { ($0.coordinate, $0.isBold) })
    }

    /// The terrain instance for the current quest — supplies `sometimesEmpty`
    /// for the yellow GYR tint.
    private var overworldInstance: OverworldInstance {
        OverworldInstance(quest: quest)
    }

    /// The green/yellow/red tint for a highlighted screen (T-015.4).
    private func gyrColor(column: Int, row: Int, mark: OverworldTileMark) -> Color {
        switch OverworldRouteTint.forHighlightedTile(
            markRawIndex: mark.rawIndex,
            gettable: mapState.owGettableLocations[column, row],
            sometimesEmpty: overworldInstance.sometimesEmpty(x: column, y: row)
        ) {
        case .green: .green
        case .yellow: .yellow
        case .red: .red
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let tileWidth = geometry.size.width / CGFloat(OverworldGrid.columnCount)
            let tileHeight = tileWidth / tileAspectRatio
            let highlights = highlightByCoordinate

            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    ForEach(0..<OverworldGrid.rowCount, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<OverworldGrid.columnCount, id: \.self) { column in
                                let mark = grid.mark(column: column, row: row)
                                let background = OverworldBackgroundAtlas.tile(quest: quest, column: column, row: row)
                                let isAlwaysEmpty = overworldInstance.alwaysEmpty(x: column, y: row)
                                let showsFairy = isAlwaysEmpty && OverworldFairySpots.isFairySpot(column: column, row: row, quest: quest)
                                let used = grid.isUsed(column: column, row: row)
                                let shopSecondItem = grid.shopSecondItem(column: column, row: row)
                                let dungeonDone: Bool = { if case .dungeon(let n) = mark { return dungeonComplete(n) } else { return false } }()
                                TileView(mark: mark, background: background, tileWidth: tileWidth, tileHeight: tileHeight, isAlwaysEmpty: isAlwaysEmpty, showsFairy: showsFairy, mirrored: mirrored, hideDungeonNumbers: hideDungeonNumbers, used: used, shopSecondItem: shopSecondItem, hideMarks: overlays?.isActive(.hideMarks) ?? false, dungeonComplete: dungeonDone)
                                    .overlay {
                                        if options.highlightNearby, !isAlwaysEmpty,
                                           let isBold = highlights[OverworldScreenCoordinate(x: column, y: row)] {
                                            // True GYR (T-015.4): green = accessible, yellow =
                                            // sometimes-empty, red = inaccessible, per the
                                            // reference's doComputedDrawing cascade. Bold/pale is
                                            // the reachability `isBold` axis, rendered as opacity.
                                            Rectangle().fill(gyrColor(column: column, row: row, mark: mark).opacity(isBold ? 0.45 : 0.2))
                                        }
                                    }
                                    .overlay {
                                        // Top-section overlay toggles (T-035.2): open-caves /
                                        // money highlights, previewed on hover / locked on click.
                                        if !isAlwaysEmpty, overlayHighlights(column: column, row: row, mark: mark) {
                                            RoundedRectangle(cornerRadius: 2)
                                                .strokeBorder(Color.green, lineWidth: 2)
                                                .background(RoundedRectangle(cornerRadius: 2).fill(Color.green.opacity(0.18)))
                                        }
                                    }
                                    .overlay {
                                        // Zones (T-035.3): tint each screen by its overworld region.
                                        if overlays?.isActive(.zones) == true {
                                            Rectangle().fill(OverworldZones.color(column: column, row: row).opacity(0.4))
                                        }
                                    }
                                    .overlay {
                                        // Coords (T-035.3): the screen's A1…H16 coordinate.
                                        if overlays?.isActive(.coords) == true {
                                            Text(OverworldCoords.label(column: column, row: row))
                                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                                .foregroundStyle(.white)
                                                .shadow(color: .black, radius: 1)
                                                .padding(1)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                                // Counter-flip so the coord reads normally under a
                                                // mirrored map (it still marks its true screen).
                                                .scaleEffect(x: mirrored ? -1 : 1, y: 1)
                                        }
                                    }
                                    .overlay {
                                        // Recorder-warp destination marker (T-035.7): a lone cyan
                                        // diamond on the *current* destination screen only.
                                        if !isAlwaysEmpty,
                                           recorderDestination == OverworldScreenCoordinate(x: column, y: row) {
                                            Rectangle()
                                                .fill(Color.cyan)
                                                .frame(width: tileHeight * 0.24, height: tileHeight * 0.24)
                                                .rotationEffect(.degrees(45))
                                                .overlay(Rectangle().stroke(.black, lineWidth: 0.5).rotationEffect(.degrees(45)))
                                                .padding(2)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                                .scaleEffect(x: mirrored ? -1 : 1, y: 1)
                                        }
                                    }
                                    .overlay {
                                        // Start-spot marker (T-035.8): a lime ring on a violet
                                        // glow, centered on the player's spawn screen.
                                        if startSpot == OverworldScreenCoordinate(x: column, y: row) {
                                            Circle()
                                                .stroke(Color(red: 0.58, green: 0, blue: 0.83), lineWidth: 4)
                                                .overlay(Circle().stroke(Color(red: 0.5, green: 1, blue: 0), lineWidth: 2))
                                                .frame(width: tileHeight * 0.62, height: tileHeight * 0.62)
                                                .shadow(color: Color(red: 0.58, green: 0, blue: 0.83), radius: 2)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                .allowsHitTesting(false)
                                        }
                                    }
                                    .onTapGesture { handleLeftClick(column: column, row: row) }
                                    .contextMenu { markMenu(column: column, row: row) }
                                    .onContinuousHover { phase in
                                        handleHover(column: column, row: row, phase: phase, tileWidth: tileWidth, tileHeight: tileHeight)
                                    }
                                    // Always-empty screens can never contain anything, so they
                                    // are permanent "don't care" and take no input (the reference
                                    // makes them a non-interactive opaque layer).
                                    .allowsHitTesting(!isAlwaysEmpty)
                                    // Custom-drawn tiles (Rectangle + onTapGesture) have NO
                                    // accessibility representation by default -- confirmed by
                                    // inspecting the accessibility tree while testing this view,
                                    // not assumed. VoiceOver users could not otherwise perceive
                                    // or activate any of these 128 tiles. See docs/ux.md
                                    // "Accessibility baseline" -- this is the first view with
                                    // fully custom interactive elements, so it's handled here
                                    // rather than deferred again.
                                    .accessibilityElement(children: .ignore)
                                    .accessibilityLabel("Overworld tile, column \(column + 1), row \(row + 1)")
                                    .accessibilityValue(isAlwaysEmpty ? "Always empty (nothing here)" : mark.displayName)
                                    .accessibilityAddTraits(.isButton)
                                    .accessibilityAction { handleLeftClick(column: column, row: row) }
                            }
                        }
                    }
                }
                if options.drawRoutes, let routeHighlight {
                    OverworldRouteLinesOverlay(lines: routeHighlight.lines, tileWidth: tileWidth, tileHeight: tileHeight)
                        .allowsHitTesting(false)
                }
            }
            // Mirror the whole map East↔West (T-047). scaleEffect flips both the
            // rendering and the hit-test coordinate space, so taps still land on
            // the correct (mirrored) tile; per-tile glyphs are counter-flipped
            // inside `TileView` / the coords overlay so they stay readable.
            .scaleEffect(x: mirrored ? -1 : 1, y: 1)
        }
        .aspectRatio(tileAspectRatio * CGFloat(OverworldGrid.columnCount) / CGFloat(OverworldGrid.rowCount), contentMode: .fit)
    }

    /// Hover-triggered route computation, ported structurally from the
    /// reference app's mouse-move-driven `drawPathsImpl` calls
    /// (`Z1R_Avalonia/UI.fs:80-94`) — recomputed on every hover update just
    /// as the reference recomputes on every mouse move, since the graph is
    /// small enough (~140 vertices) for this to be cheap.
    private func handleHover(column: Int, row: Int, phase: HoverPhase, tileWidth: CGFloat, tileHeight: CGFloat) {
        guard options.drawRoutes || options.highlightNearby else {
            hoveredVertex = nil
            routeHighlight = nil
            return
        }
        switch phase {
        case .active(let location):
            guard
                let graph = dynamicGraph,
                let screenType = graph.screenTypes[OverworldScreenCoordinate(x: column, y: row)]
            else { return }
            let portion: OverworldScreenPortion
            switch screenType {
            case .whole: portion = .full
            case .northSouth: portion = location.y > tileHeight / 2 ? .south : .north
            case .eastWest: portion = location.x > tileWidth / 2 ? .east : .west
            }
            let vertex = OverworldVertex(column, row, portion)
            guard vertex != hoveredVertex else { return }
            hoveredVertex = vertex

            var unmarkedScreens: Set<OverworldScreenCoordinate> = []
            for gridRow in 0..<OverworldGrid.rowCount {
                for gridColumn in 0..<OverworldGrid.columnCount where grid.mark(column: gridColumn, row: gridRow) == .unmarked {
                    unmarkedScreens.insert(OverworldScreenCoordinate(x: gridColumn, y: gridRow))
                }
            }
            routeHighlight = OverworldRoutingGraph.routeHighlight(
                from: vertex,
                unmarkedScreens: unmarkedScreens,
                screenTypes: graph.screenTypes,
                adjacency: graph.adjacency,
                maxBold: options.highlightNearby ? Self.maxGYR : 0,
                maxPale: options.highlightNearby ? Self.maxGYR : 0
            )
        case .ended:
            hoveredVertex = nil
            routeHighlight = nil
        }
    }

    private func handleLeftClick(column: Int, row: Int) {
        // Always-empty screens are permanent "don't care" and never editable
        // (defensive — the tile also sets `.allowsHitTesting(false)`).
        if overworldInstance.alwaysEmpty(x: column, y: row) { return }
        // "LC unmarked → mark dark" (docs/domain.md § 4.5). Left-click on an
        // already-dark tile is handled by the context menu, matching "LC
        // dark tile ... → popup" — SwiftUI's contextMenu also responds to a
        // plain click when attached this way is avoided by only mutating
        // state here for the unmarked case.
        let mark = grid.mark(column: column, row: row)
        if mark == .unmarked {
            grid.setMark(.dontCare, column: column, row: row)
        } else if mark == .takeAny {
            // A take-any tile cycles its claimed version (untaken → heart →
            // potion → candle), kept in sync with its Items-group slot (T-066).
            onCycleTakeAny(column, row)
        } else if mark.isUsedToggleable {
            // A claimable tile (secret / armos / letter / hint shop / sword):
            // left-click toggles it used ⇄ unused (T-054).
            grid.toggleUsed(column: column, row: row)
        }
    }

    /// Set a tile's mark from the picker. A claimable mark (secret / take-any /
    /// armos / letter / hint shop) defaults to **used** — you usually mark one
    /// right after collecting it; a left-click flips it back to unused (T-056).
    private func applyMark(_ mark: OverworldTileMark, column: Int, row: Int) {
        // If this tile was a take-any, changing it to anything else frees its
        // linked Items-group heart slot back to empty (T-066).
        if grid.mark(column: column, row: row) == .takeAny {
            onReleaseTakeAny(column, row)
        }
        grid.setMark(mark, column: column, row: row)
        if mark.isUsedToggleable {
            grid.setUsed(true, column: column, row: row)
        }
        // A shop can't hold the same item twice (T-060): if the new primary
        // matches the recorded second item, clear the second.
        if case .shop(let item1) = mark, grid.shopSecondItem(column: column, row: row) == item1 {
            grid.setShopSecondItem(nil, column: column, row: row)
        }
        // Placing a dungeon auto-sets its location hint to this screen's region
        // (T-039.1).
        if case .dungeon(let number) = mark {
            onPlaceDungeon(number, column, row)
        }
    }

    /// Mark a take-any cave and record what was taken (T-057/T-066). Delegated
    /// to the model so the tile's linked Items-group heart slot stays in sync:
    /// the tile reuses its own slot when re-marked, and `.untaken` frees it.
    private func applyTakeAny(_ state: TakeAnyHeartState, column: Int, row: Int) {
        onSetTakeAny(state, column, row)
    }

    /// Count of each mark across the grid — for disabling exhausted picker
    /// options (T-058).
    private var markCounts: [OverworldTileMark: Int] {
        var counts: [OverworldTileMark: Int] = [:]
        for c in 0..<OverworldGrid.columnCount {
            for r in 0..<OverworldGrid.rowCount {
                counts[grid.mark(column: c, row: r), default: 0] += 1
            }
        }
        return counts
    }

    /// Whether placing `mark` at this tile would exceed its per-quest max — i.e.
    /// its option should be disabled. The current tile's own mark doesn't count
    /// against the limit (re-selecting it is a no-op).
    private func isExhausted(_ mark: OverworldTileMark, column: Int, row: Int, counts: [OverworldTileMark: Int]) -> Bool {
        let current = grid.mark(column: column, row: row)
        let otherCount = (counts[mark] ?? 0) - (current == mark ? 1 : 0)
        return otherCount >= OverworldTileLimits.maxUses(mark, quest: quest)
    }

    /// Whether **every** mark in a submenu is exhausted — disables the parent
    /// menu itself (T-059), e.g. "Dungeon" once all nine are placed.
    private func allExhausted(_ marks: [OverworldTileMark], column: Int, row: Int, counts: [OverworldTileMark: Int]) -> Bool {
        marks.allSatisfy { isExhausted($0, column: column, row: row, counts: counts) }
    }

    @ViewBuilder
    private func markMenu(column: Int, row: Int) -> some View {
        let counts = markCounts
        Button("Clear (unmarked)") { applyMark(.unmarked, column: column, row: row) }
        Button("Don't care") { applyMark(.dontCare, column: column, row: row) }
        Divider()
        Menu("Dungeon") {
            ForEach(1...9, id: \.self) { number in
                // HDN labels dungeons A–H (Level 9 stays "9"); the mark still
                // stores the slot number, so located-linking is unchanged.
                let label = DungeonLabeling.slotLabel(number, hideDungeonNumbers: hideDungeonNumbers)
                Button(number == 9 ? "Level 9" : "Dungeon \(label)") {
                    applyMark(.dungeon(number), column: column, row: row)
                }
                .disabled(isExhausted(.dungeon(number), column: column, row: row, counts: counts))
            }
        }
        .disabled(allExhausted((1...9).map { .dungeon($0) }, column: column, row: row, counts: counts))
        Menu("Any road") {
            ForEach(1...4, id: \.self) { number in
                Button("Any road \(number)") { applyMark(.anyRoad(number), column: column, row: row) }
                    .disabled(isExhausted(.anyRoad(number), column: column, row: row, counts: counts))
            }
        }
        .disabled(allExhausted((1...4).map { .anyRoad($0) }, column: column, row: row, counts: counts))
        Menu("Sword cave") {
            ForEach(1...3, id: \.self) { number in
                Button(Self.swordCaveLabel(number)) {
                    applyMark(.swordCave(number), column: column, row: row)
                }
                .disabled(isExhausted(.swordCave(number), column: column, row: row, counts: counts))
            }
        }
        .disabled(allExhausted((1...3).map { .swordCave($0) }, column: column, row: row, counts: counts))
        Menu("Shop") {
            ForEach(ShopKind.allCases, id: \.self) { kind in
                Button(kind.shortName) { applyMark(.shop(kind), column: column, row: row) }
            }
        }
        // A shop tile carries two items (T-060) — its second item is set here.
        if case .shop(let item1) = grid.mark(column: column, row: row) {
            Menu("Shop — 2nd item") {
                Button("None") { grid.setShopSecondItem(nil, column: column, row: row) }
                ForEach(ShopKind.allCases, id: \.self) { kind in
                    Button(kind.shortName) { grid.setShopSecondItem(kind, column: column, row: row) }
                        .disabled(kind == item1) // no duplicate item
                }
            }
        }
        Menu("Secret") {
            ForEach(SecretSize.allCases, id: \.self) { size in
                Button(size.displayName) { applyMark(.secret(size), column: column, row: row) }
            }
        }
        // Take-any is a submenu (Unclaimed / Potion / Blue candle / Heart since
        // T-057), so it belongs with the other submenus rather than down among
        // the one-shot marks where it used to live as a plain button (T-063).
        Menu("Take any") {
            Button("Unclaimed") { applyTakeAny(.untaken, column: column, row: row) }
            Button("Potion") { applyTakeAny(.takenPotion, column: column, row: row) }
            Button("Blue candle") { applyTakeAny(.takenCandle, column: column, row: row) }
            Button("Heart") { applyTakeAny(.takenHeart, column: column, row: row) }
        }
        .disabled(isExhausted(.takeAny, column: column, row: row, counts: counts))
        Divider()
        Button("Door repair") { applyMark(.doorRepair, column: column, row: row) }
            .disabled(isExhausted(.doorRepair, column: column, row: row, counts: counts))
        Button("Money making game") { applyMark(.moneyMakingGame, column: column, row: row) }
            .disabled(isExhausted(.moneyMakingGame, column: column, row: row, counts: counts))
        Button("The letter") { applyMark(.theLetter, column: column, row: row) }
            .disabled(isExhausted(.theLetter, column: column, row: row, counts: counts))
        Button("Armos") { applyMark(.armos, column: column, row: row) }
            .disabled(isExhausted(.armos, column: column, row: row, counts: counts))
        Button("Hint shop") { applyMark(.hintShop, column: column, row: row) }
            .disabled(isExhausted(.hintShop, column: column, row: row, counts: counts))
        Button("Potion shop") { applyMark(.potionShop, column: column, row: row) }
            .disabled(isExhausted(.potionShop, column: column, row: row, counts: counts))
        Divider()
        // Start spot (T-035.8): a placeable spawn-screen marker, independent of
        // the tile's mark.
        if startSpot == OverworldScreenCoordinate(x: column, y: row) {
            Button("Clear start spot") { onClearStartSpot() }
        } else {
            Button("Set as start spot") { onSetStartSpot(column, row) }
        }
    }
}

/// A single tile's visual: the real terrain background (T-008) as the base
/// layer, with the real tile-mark interior icon composited centered on top
/// wherever a mark is set. `.unmarked` tiles show terrain alone, undecorated
/// — matching how the reference app's map looks before the player has
/// marked anything.
///
/// **Bugfix, not the original design:** this used to overlay a full-tile
/// icon cropped from `s_icon_overworld_strip39.png`. That file is dead code
/// in the reference app (see `OverworldTileMark.iconSource`'s doc comment)
/// — the real interior icon is much smaller than the tile (5×9 of a 16×11
/// tile) and centered within it, composited from up to three different
/// sources depending on the mark. Position/size fractions below are ported
/// exactly from `Graphics.fs`'s `initFull()` (`:947-960`): interior region
/// is `x∈[5,10), y∈[1,10)` within the 16×11 tile.
/// The fixed fairy-fountain overworld screens (`WPFUI.fs:488-490`): `(9,3)`
/// and `(3,4)` in every quest, plus `(11,0)` in second quest only. Pure +
/// testable. (These coordinates are always-empty in the relevant quests, so
/// the fairy is only ever drawn on an always-empty tile.)
enum OverworldFairySpots {
    static func isFairySpot(column: Int, row: Int, quest: OverworldQuest) -> Bool {
        if column == 9 && row == 3 { return true }
        if column == 3 && row == 4 { return true }
        if quest == .second && column == 11 && row == 0 { return true }
        return false
    }
}

/// Loads the fairy sprite (`icons8x16.png`, 8×16px, the whole image, with
/// black keyed transparent — `Graphics.fs:684-693`).
enum FairyIconAtlas {
    static let image: CGImage? = AtlasLoader.load("icons8x16", blackIsTransparent: true)
}

private struct TileView: View {
    var mark: OverworldTileMark
    var background: CGImage?
    var tileWidth: CGFloat
    var tileHeight: CGFloat
    /// This screen can never contain anything for the current quest
    /// (`OverworldInstance.alwaysEmpty`) — rendered as a permanent, non-
    /// editable darkened "don't care" tile (`WPFUI.fs:244`).
    var isAlwaysEmpty: Bool = false
    /// This always-empty screen is a fixed fairy-fountain spot and shows the
    /// fairy icon (`WPFUI.fs:488-490`).
    var showsFairy: Bool = false
    /// Whether the map is mirrored (T-047). The terrain sprite stays flipped
    /// (the map is genuinely mirrored), but glyph layers — dungeon/any-road
    /// numerals, interior icons, the fairy — are counter-flipped so they read
    /// normally, matching the reference's re-flip of readable elements.
    var mirrored: Bool = false
    /// Hidden Dungeon Numbers (T-049): render dungeon digits 1–8 as A–H.
    var hideDungeonNumbers: Bool = false
    /// This claimable tile has been marked **used** (collected) — T-054;
    /// dimmed with a check so it reads as done.
    var used: Bool = false
    /// A shop tile's second item (T-060); both are drawn in `ShopKind` order.
    var shopSecondItem: ShopKind? = nil
    /// The "Hide tile icons" view control is active (T-062): suppress every
    /// user-placed mark layer (digit badge, interior/shop icon, dark/used
    /// shading) so only the raw terrain (plus always-empty / fairy truth) shows.
    var hideMarks: Bool = false
    /// This tile's dungeon is 100% complete (T-035.6) — its digit/letter badge
    /// dims from bright yellow to dark yellow.
    var dungeonComplete: Bool = false

    private static let interiorOffsetXFraction: CGFloat = 5.0 / 16.0
    private static let interiorOffsetYFraction: CGFloat = 1.0 / 11.0
    private static let interiorWidthFraction: CGFloat = 5.0 / 16.0
    private static let interiorHeightFraction: CGFloat = 9.0 / 11.0

    /// Ported from `Color.Orchid` (`Z1R_WPF/Graphics.fs:886-892`, any-road
    /// digit background) — .NET's standard Orchid RGB value.
    private static let anyRoadBackground = Color(red: 218.0 / 255, green: 112.0 / 255, blue: 214.0 / 255)
    /// The completed-dungeon dark yellow (`RGB(153,153,0)`,
    /// `Graphics.fs:874-884`) — a 100%-complete dungeon's badge dims to this.
    private static let completeDungeonBackground = Color(red: 153.0 / 255, green: 153.0 / 255, blue: 0)
    /// Ported from `itemBackgroundColor` (`Z1R_WPF/Graphics.fs:830`, shop
    /// icon background).
    private static let shopBackground = Color(red: 0xEF / 255.0, green: 0x83 / 255.0, blue: 0)

    var body: some View {
        ZStack(alignment: .topLeading) {
            backgroundView
            // When "Hide tile icons" is active (T-062), every user-placed mark
            // layer is suppressed so the terrain reads cleanly — only the
            // always-empty / fairy truth below still draws.
            if !hideMarks {
                // .dontCare ("dark") darkens the terrain rather than blacking it
                // out entirely, so the underlying map stays readable (aesthetic
                // improvement over the reference's solid-black fill).
                if mark.iconSource == .solidBlackTile {
                    Rectangle().fill(.black.opacity(0.62))
                }
                // Dungeon / any-road numbers render as a larger centered badge
                // (not confined to the tiny 5px interior-icon region) so they're
                // legible at map scale.
                digitBadge
                    .frame(width: tileWidth, height: tileHeight)
                    .scaleEffect(x: mirrored ? -1 : 1, y: 1)
                // Sword caves use the high-fidelity Items-area sword sprite on a
                // dark plate (like the item boxes), sized like the digit badge
                // so it reads at map scale — T-063.
                swordCaveBadge
                    .frame(width: tileWidth, height: tileHeight)
                    .scaleEffect(x: mirrored ? -1 : 1, y: 1)
                // Interior sprites (secrets, door repair, money game, letter,
                // armos, hint shop, take-any, potion) are enlarged and centered
                // so they read at map scale, matching the dungeon-number / sword
                // fidelity — no longer confined to the tiny off-center reference
                // interior region (T-064, same art, just bigger + centered).
                interiorSpriteView
                    .frame(width: tileWidth, height: tileHeight)
                    .scaleEffect(x: mirrored ? -1 : 1, y: 1)
                // Shops keep the orange-plate presentation in the reference
                // interior region (their two 3×7 item icons already read well).
                shopIconView
                    .frame(width: tileWidth * Self.interiorWidthFraction, height: tileHeight * Self.interiorHeightFraction)
                    .scaleEffect(x: mirrored ? -1 : 1, y: 1)
                    .offset(x: tileWidth * Self.interiorOffsetXFraction, y: tileHeight * Self.interiorOffsetYFraction)
            }
            // Permanent "always empty" screens are simply darkened (same as a
            // user `.dontCare` mark) — a darkened tile already reads as
            // "nothing here", so no extra glyph. A few of them are fixed
            // fairy-fountain spots, which do get the fairy icon.
            if isAlwaysEmpty {
                Rectangle().fill(.black.opacity(0.62))
                    .frame(width: tileWidth, height: tileHeight)
                if showsFairy, let fairy = FairyIconAtlas.image {
                    Image(decorative: fairy, scale: 1, orientation: .up)
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: tileHeight * 0.7, height: tileHeight * 0.7)
                        .frame(width: tileWidth, height: tileHeight)
                        .scaleEffect(x: mirrored ? -1 : 1, y: 1)
                }
            }
            // A claimed ("used") tile — or a 100%-complete dungeon (T-035.6) —
            // gets the full-tile dim so it reads as "done" like every other
            // collected tile (the dark-yellow badge alone wasn't enough). The
            // darkened tile + icon convey done, so no extra glyph (T-054).
            // Suppressed with the rest of the mark layers under "Hide tile
            // icons" (T-062).
            if used || dungeonComplete, !hideMarks {
                Rectangle().fill(.black.opacity(0.55))
                    .frame(width: tileWidth, height: tileHeight)
            }
        }
        .frame(width: tileWidth, height: tileHeight)
        .clipped()
        .overlay(Rectangle().stroke(.black.opacity(0.3), lineWidth: 0.5))
    }

    @ViewBuilder
    private var backgroundView: some View {
        if let background {
            Image(decorative: background, scale: 1, orientation: .up)
                .resizable()
                .interpolation(.none)
                .aspectRatio(contentMode: .fill)
        } else {
            Rectangle().fill(.gray.opacity(0.3))
        }
    }

    @ViewBuilder
    private var digitBadge: some View {
        switch mark.iconSource {
        case .dungeonDigit(let number):
            // HDN relabels dungeons 1–8 as A–H (Level 9 stays "9"); any-road
            // digits are unaffected. A completed dungeon dims to dark yellow.
            digitIcon(DungeonLabeling.slotLabel(number, hideDungeonNumbers: hideDungeonNumbers),
                      background: dungeonComplete ? Self.completeDungeonBackground : .yellow)
        case .anyRoadDigit(let number):
            digitIcon("\(number)", background: Self.anyRoadBackground)
        default:
            EmptyView()
        }
    }

    /// The Items-area sword sprite (wood / white / magical for cave levels
    /// 1 / 2 / 3) — the high-fidelity replacement for the numbered ow sprite.
    private static func swordIcon(forCaveLevel level: Int) -> ItemIconAtlas.Icon? {
        switch level {
        case 1: .brownSword
        case 2: .whiteSword
        case 3: .magicalSword
        default: nil
        }
    }

    @ViewBuilder
    private var swordCaveBadge: some View {
        if case .swordCaveItem(let level) = mark.iconSource,
           let icon = Self.swordIcon(forCaveLevel: level),
           let image = Image(atlasIcon: ItemIconAtlas.cgImage(icon)) {
            let badge = min(tileWidth, tileHeight) * 0.82
            RoundedRectangle(cornerRadius: badge * 0.18)
                .fill(.black.opacity(0.82))
                .overlay(
                    image.interpolation(.none).resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(badge * 0.14)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: badge * 0.18)
                        .strokeBorder(.black.opacity(0.55), lineWidth: 1)
                )
                .frame(width: badge, height: badge)
        }
    }

    /// The plain interior sprites (everything except shops), rendered large and
    /// centered within the tile at their native 5×9 aspect (T-064). `.fit` keeps
    /// the pixel art undistorted; the height cap leaves a small margin so the
    /// sprite doesn't touch the tile border.
    @ViewBuilder
    private var interiorSpriteView: some View {
        if case .interiorSprite(let index) = mark.iconSource,
           let icon = OverworldInteriorIconAtlas.icon(at: index) {
            Image(decorative: icon, scale: 1, orientation: .up)
                .resizable()
                .interpolation(.none) // crisp nearest-neighbor, matches the reference's integer scaling
                .aspectRatio(contentMode: .fit)
                .frame(width: tileWidth, height: tileHeight * 0.9)
        }
    }

    @ViewBuilder
    private var shopIconView: some View {
        if case .shopSprite = mark.iconSource {
            let interiorBoxHeight = tileHeight * Self.interiorHeightFraction
            ZStack {
                Self.shopBackground
                // Shops carry up to two items (T-060), drawn side by side in
                // `ShopKind` order for a stable layout.
                HStack(spacing: 0) {
                    ForEach(orderedShopItems, id: \.self) { kind in
                        if let icon = OverworldShopIconAtlas.icon(at: ShopKind.allCases.firstIndex(of: kind) ?? 0) {
                            Image(decorative: icon, scale: 1, orientation: .up)
                                .resizable()
                                .interpolation(.none)
                                .aspectRatio(3.0 / 7.0, contentMode: .fit)
                        }
                    }
                }
                .padding(.vertical, interiorBoxHeight / 9.0)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    /// This shop's items in `ShopKind` display order (primary from the mark +
    /// the second item, deduped) — T-060.
    private var orderedShopItems: [ShopKind] {
        guard case .shop(let first) = mark else { return [] }
        var kinds = [first]
        if let second = shopSecondItem, second != first { kinds.append(second) }
        return kinds.sorted {
            (ShopKind.allCases.firstIndex(of: $0) ?? 0) < (ShopKind.allCases.firstIndex(of: $1) ?? 0)
        }
    }

    /// A centered colored badge with a bold label (a dungeon/any-road number, or
    /// an A–H dungeon letter under HDN), sized to most of the tile so it's
    /// legible at map scale.
    private func digitIcon(_ label: String, background: Color) -> some View {
        let badge = min(tileWidth, tileHeight) * 0.82
        return RoundedRectangle(cornerRadius: badge * 0.18)
            .fill(background)
            .overlay(
                Text(label)
                    .font(.system(size: badge * 0.8, weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.3)
                    .foregroundStyle(.black)
            )
            .overlay(
                RoundedRectangle(cornerRadius: badge * 0.18)
                    .strokeBorder(.black.opacity(0.55), lineWidth: 1)
            )
            .frame(width: badge, height: badge)
    }
}

/// Loads the reference app's real overworld interior-icon strip
/// (`ow_icons5x9.png`, 14 icons of 5×9px each) and crops individual icons on
/// demand. Covers sword caves, secrets, door repair, money making game, the
/// letter, armos, hint shop, take-any, and the potion shop — grounded in
/// `Graphics.fs`'s `theInteriorBmpTable` construction (`:850-945`) and
/// verified icon-by-icon against the actual strip pixels, not assumed from
/// the filename.
enum OverworldInteriorIconAtlas {
    static let iconWidth = 5
    static let iconHeight = 9
    static let iconCount = 14

    private static let fullImage: CGImage? = {
        guard
            let url = Bundle.module.url(forResource: "ow_icons5x9", withExtension: "png"),
            let dataProvider = CGDataProvider(url: url as CFURL),
            let image = CGImage(
                pngDataProviderSource: dataProvider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        else { return nil }
        return image
    }()

    static func icon(at index: Int) -> CGImage? {
        guard let fullImage, (0..<iconCount).contains(index) else { return nil }
        let rect = CGRect(x: index * iconWidth, y: 0, width: iconWidth, height: iconHeight)
        return fullImage.cropping(to: rect)
    }
}

/// Loads the reference app's real shop-item icon strip (`icons3x7.png`, 8
/// icons of 3×7px each — Arrow/Bomb/Book/BlueCandle/BlueRing/Meat/Key/Shield,
/// matching `MapSquareChoiceDomainHelper`'s `ARROW`...`SHIELD` order exactly)
/// and crops individual icons on demand.
enum OverworldShopIconAtlas {
    static let iconWidth = 3
    static let iconHeight = 7
    static let iconCount = 8

    private static let fullImage: CGImage? = {
        guard
            let url = Bundle.module.url(forResource: "icons3x7", withExtension: "png"),
            let dataProvider = CGDataProvider(url: url as CFURL),
            let image = CGImage(
                pngDataProviderSource: dataProvider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        else { return nil }
        return image
    }()

    static func icon(at index: Int) -> CGImage? {
        guard let fullImage, (0..<iconCount).contains(index) else { return nil }
        let rect = CGRect(x: index * iconWidth, y: 0, width: iconWidth, height: iconHeight)
        return fullImage.cropping(to: rect)
    }
}

/// Loads the reference app's overworld terrain-art strip once and crops
/// individual 16×11px terrain tiles on demand, per quest (T-008). The
/// source (`s_map_overworld_vanilla_strip8.png`, 1280×88px) is 5
/// horizontal sections of 256×88px each — the first 4 are the real quest
/// layouts (`OverworldQuest.referenceAppIndex`, grounded in
/// `OverworldData.fs`'s `OWQuest.AsInt`), the 5th is unused/blank (the
/// reference app's `OWQuest.BLANK`, which maps to the already-deferred
/// "alternative overworld map" mode — not read here). Each 256×88px section
/// is itself a 16×8 grid of 16×11px tiles, identical in shape to
/// `OverworldIconAtlas`'s icons — confirmed via `Graphics.fs`'s
/// `overworldMapBMPs` pixel-indexing math, not guessed.
enum OverworldBackgroundAtlas {
    static let tileWidth = 16
    static let tileHeight = 11
    static let sectionWidth = tileWidth * OverworldGrid.columnCount // 256
    static let questCount = 4 // FIRST, SECOND, MIXED_FIRST, MIXED_SECOND -- BLANK excluded, see above

    private static let fullImage: CGImage? = {
        guard
            let url = Bundle.module.url(forResource: "s_map_overworld_vanilla_strip8", withExtension: "png"),
            let dataProvider = CGDataProvider(url: url as CFURL),
            let image = CGImage(
                pngDataProviderSource: dataProvider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        else { return nil }
        return image
    }()

    static func tile(quest: OverworldQuest, column: Int, row: Int) -> CGImage? {
        guard
            let fullImage,
            (0..<OverworldGrid.columnCount).contains(column),
            (0..<OverworldGrid.rowCount).contains(row)
        else { return nil }
        let sectionX = quest.referenceAppIndex * sectionWidth
        let rect = CGRect(
            x: sectionX + column * tileWidth,
            y: row * tileHeight,
            width: tileWidth,
            height: tileHeight
        )
        return fullImage.cropping(to: rect)
    }
}

/// Draws the hover-triggered route lines (T-011) on top of the grid, using
/// coordinates computed as a *fraction* of each tile's current on-screen
/// size — the reference app's `coords` function
/// (`OverworldRouteDrawing.fs:72-80`) uses fixed absolute pixel offsets into
/// a fixed-size `Canvas`, which doesn't hold up under this app's responsive,
/// reflowing layout (`docs/decisions/0003-responsive-layout-not-fixed-presets.md`);
/// this recomputes from the actual current `tileWidth`/`tileHeight` every
/// layout pass instead.
private struct OverworldRouteLinesOverlay: View {
    var lines: [OverworldRouteLineSegment]
    var tileWidth: CGFloat
    var tileHeight: CGFloat

    var body: some View {
        Canvas { context, _ in
            for line in lines {
                var path = Path()
                path.move(to: point(for: line.from))
                path.addLine(to: point(for: line.to))
                context.stroke(path, with: .color(color(forCost: line.cost)), lineWidth: 2)
            }
        }
    }

    private func point(for vertex: OverworldVertex) -> CGPoint {
        let offset = OverworldRouteGeometry.fractionalOffset(for: vertex.portion)
        return CGPoint(
            x: (CGFloat(vertex.x) + offset.x) * tileWidth,
            y: (CGFloat(vertex.y) + offset.y) * tileHeight
        )
    }

    /// Opacity tiers ported from `OverworldRouteDrawing.fs`'s `color(cost)`
    /// function (`:130-137`) — a white line, brightest near the hovered
    /// tile, fading as path cost increases.
    private func color(forCost cost: Int) -> Color {
        if cost <= 8 { .white.opacity(0.706) }
        else if cost <= 14 { .white.opacity(0.588) }
        else if cost <= 22 { .white.opacity(0.47) }
        else if cost <= 30 { .white.opacity(0.392) }
        else { .white.opacity(0.333) }
    }
}

/// Where each screen portion sits within its own tile's bounds, as a
/// fraction of tile width/height — converted from the reference app's
/// absolute-pixel offsets (`OverworldRouteDrawing.fs:72-80`: tile is 48×33px
/// at the reference's fixed 3x zoom, offsets are `8*3`/`5*3` for center and
/// `±4`/`±6`/`±8`/`±12` for the half-screen portions) so the same relative
/// layout holds at any tile size.
private enum OverworldRouteGeometry {
    static func fractionalOffset(for portion: OverworldScreenPortion) -> (x: CGFloat, y: CGFloat) {
        switch portion {
        case .full: (0.5, 0.5)
        case .north: (0.5 + 4.0 / 48.0, 0.5 - 8.0 / 33.0)
        case .south: (0.5 - 6.0 / 48.0, 0.5 + 8.0 / 33.0)
        case .east: (0.5 + 12.0 / 48.0, 0.5)
        case .west: (0.5 - 12.0 / 48.0, 0.5)
        }
    }
}

#Preview {
    let grid = OverworldGrid()
    let playerState = PlayerComputedStateSummary(haveLadder: true, haveRaft: true)
    OverworldMapView(
        grid: grid,
        quest: .first,
        options: TrackerOptions(),
        playerState: playerState,
        mapState: MapStateSummary.compute(
            grid: grid,
            instance: OverworldInstance(quest: .first),
            dungeonTracker: DungeonTrackerInstance(),
            playerState: playerState,
            progress: PlayerProgressAndTakeAnyHearts(),
            drawRoutes: true,
            routesCanScreenScroll: false,
            mirrorOverworld: false
        )
    )
    .frame(width: 800)
    .padding()
}
