import SwiftUI
import TrackerCore

/// The Shop & Price tracker breakout window (T-218): a standalone place to record shop stock +
/// prices, the two potion prices, the bomb-upgrade price, and the six paid hints (price + collected).
/// Breakout-only — a lesser-used feature we keep off the main interface.
struct ShopPriceView: View {
    @Bindable var record: ShopPriceRecord
    /// Reuses the overworld's graphical-vs-menu chooser preference for the item picker (T-218).
    var options: TrackerOptions

    private static let potionBlueSprite = "Life Potion"
    private static let potionRedSprite = "2nd Potion"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                shopsSection
                Divider()
                potionsAndBombs
                Divider()
                hintsSection
                Divider()
                HStack {
                    Spacer()
                    Button(role: .destructive) { record.clearAll() } label: {
                        Label("Clear all", systemImage: "trash")
                    }
                    .controlSize(.small)
                    .disabled(record.isEmpty)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Shops

    private var shopsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Shops", "Click an icon to set the item (cycles through the eight shop staples); type a price.")
            Grid(horizontalSpacing: 14, verticalSpacing: 8) {
                ForEach(0..<ShopPriceRecord.shopCount, id: \.self) { shop in
                    GridRow {
                        Text("SH\(shop + 1)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .frame(width: 34, alignment: .leading)
                        ForEach(0..<ShopPriceRecord.slotsPerShop, id: \.self) { slot in
                            slotCell(shop: shop, slot: slot)
                        }
                    }
                }
            }
        }
    }

    private func slotCell(shop: Int, slot: Int) -> some View {
        HStack(spacing: 5) {
            ShopSlotItemButton(record: record, shop: shop, slot: slot,
                               graphical: options.graphicalOverworldChooser)
            PriceField(value: Binding(
                get: { record.shops[shop][slot].price },
                set: { record.shops[shop][slot].price = $0 }))
        }
    }

    // MARK: Potions + bomb upgrades

    private var potionsAndBombs: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Potions & bomb upgrades", nil)
            HStack(spacing: 20) {
                labeledPrice(label: "Blue potion", value: $record.bluePotionPrice) {
                    spriteIcon(Self.potionBlueSprite)
                }
                labeledPrice(label: "Red potion", value: $record.redPotionPrice) {
                    spriteIcon(Self.potionRedSprite)
                }
                labeledPrice(label: "Bomb upgrade ×2", value: $record.bombUpgradePrice,
                             help: "There are always two paid bomb upgrades at the same price.") {
                    ItemGlyph(.wsMsBombUpgrade)   // our existing bomb-upgrade (bomb+) icon
                }
            }
        }
    }

    @ViewBuilder private func spriteIcon(_ name: String) -> some View {
        if let cg = GameSprite.image(name) {
            Image(decorative: cg, scale: 1, orientation: .up)
                .interpolation(.none).resizable().scaledToFit()
        }
    }

    private func labeledPrice<Icon: View>(label: String, value: Binding<Int?>, help: String? = nil,
                                          @ViewBuilder icon: () -> Icon) -> some View {
        HStack(spacing: 6) {
            icon().frame(width: 26, height: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 11)).foregroundStyle(.secondary)
                PriceField(value: value)
            }
        }
        .help(help ?? label)
    }

    // MARK: Hints

    private var hintsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Hints", "Six paid hints from two hint shops. Check one off once you've bought it.")
            HStack(alignment: .top, spacing: 28) {
                ForEach(0..<ShopPriceRecord.hintShopCount, id: \.self) { shop in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Hint shop \(shop + 1)")
                            .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                        ForEach(0..<ShopPriceRecord.hintsPerShop, id: \.self) { hint in
                            hintRow(shop: shop, hint: hint)
                        }
                    }
                }
            }
        }
    }

    private func hintRow(shop: Int, hint: Int) -> some View {
        HStack(spacing: 6) {
            Toggle("", isOn: Binding(
                get: { record.hints[shop][hint].collected },
                set: { record.hints[shop][hint].collected = $0 }))
                .toggleStyle(.checkbox)
                .labelsHidden()
                .help("Collected")
            PriceField(value: Binding(
                get: { record.hints[shop][hint].price },
                set: { record.hints[shop][hint].price = $0 }))
                .opacity(record.hints[shop][hint].collected ? 0.55 : 1)
        }
    }

    // MARK: Bits

    private func sectionHeader(_ title: String, _ subtitle: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.system(size: 14, weight: .semibold))
            if let subtitle {
                Text(subtitle).font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}

/// One shop item slot: shows the current staple (or "?") and opens the staple picker on **either**
/// left- or right-click (T-218). The picker is the graphical icon grid or the text menu, following
/// the same `graphicalOverworldChooser` preference the overworld uses.
private struct ShopSlotItemButton: View {
    @Bindable var record: ShopPriceRecord
    let shop: Int
    let slot: Int
    let graphical: Bool
    @State private var showing = false

    var body: some View {
        let kind = record.shops[shop][slot].kind
        Button { showing = true } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 5).fill(Theme.boxFill)
                if let kind, let cg = GameSprite.image(GameSprite.shopFile(kind) ?? "") {
                    Image(decorative: cg, scale: 1, orientation: .up)
                        .interpolation(.none).resizable().scaledToFit()
                        .padding(4)
                        .shadow(color: .black, radius: 1)
                } else {
                    Text("?").font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 34, height: 34)
            .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .onRightClick { showing = true }
        .help(kind.map { "\($0.displayName) — click to change" } ?? "Empty — click to set the item")
        .popover(isPresented: $showing, arrowEdge: .bottom) {
            ShopStaplePicker(current: kind, graphical: graphical) { picked in
                record.shops[shop][slot].kind = picked
                showing = false
            }
        }
    }
}

/// The shop-item chooser (T-218): the eight staples as a 2×4 icon grid (graphical mode) or a text
/// list (menu mode), plus Clear. Mirrors the overworld's graphical/menu split.
private struct ShopStaplePicker: View {
    let current: ShopKind?
    let graphical: Bool
    let onPick: (ShopKind?) -> Void

    private let columns = Array(repeating: GridItem(.fixed(38), spacing: 6), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Shop item").font(.caption).foregroundStyle(.secondary)
            if graphical {
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(ShopKind.allCases, id: \.self) { kind in
                        Button { onPick(kind) } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(current == kind ? Color.accentColor.opacity(0.5) : Theme.boxFill)
                                if let cg = GameSprite.image(GameSprite.shopFile(kind) ?? "") {
                                    Image(decorative: cg, scale: 1, orientation: .up)
                                        .interpolation(.none).resizable().scaledToFit()
                                        .padding(4).shadow(color: .black, radius: 1)
                                }
                            }
                            .frame(width: 38, height: 38)
                            .overlay(RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(current == kind ? Color.accentColor : Theme.border, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .help(kind.displayName)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(ShopKind.allCases, id: \.self) { kind in
                        Button { onPick(kind) } label: {
                            Text(kind.displayName)
                                .fontWeight(current == kind ? .bold : .regular)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Divider()
            Button(role: .destructive) { onPick(nil) } label: { Label("Clear", systemImage: "xmark") }
                .controlSize(.small)
        }
        .padding(10)
        .frame(width: graphical ? 216 : 168)
    }
}

/// A compact rupee-price entry: digits only, blank = unknown. Bound to an optional Int.
private struct PriceField: View {
    @Binding var value: Int?

    var body: some View {
        TextField("—", text: Binding(
            get: { value.map(String.init) ?? "" },
            set: { value = Int($0.filter(\.isNumber)) }))
            .textFieldStyle(.roundedBorder)
            .frame(width: 54)
            .multilineTextAlignment(.trailing)
            .font(.system(size: 12, design: .monospaced))
    }
}
