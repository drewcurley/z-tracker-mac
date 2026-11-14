import AppKit
import SwiftUI

/// A popover stand-in that doesn't use `NSPopover` (T-256). The dungeon room pickers crashed
/// intermittently inside AppKit's popover service (ViewBridge) on the macOS 27 beta, especially
/// with the app in the background (T-139/T-145 notes); T-145 cut the anchors from 192 to 3, and
/// this removes NSPopover from that path entirely. The content shows in a borderless child panel
/// just below the anchor (above it if there's no room), with no open animation; it closes on Esc,
/// a click outside, or the app losing focus — like a transient popover.
extension View {
    /// Present `content` in a picker panel anchored to `anchor` (in this view's local
    /// coordinates; `.zero` anchors to the whole view).
    func pickerPanel<PanelContent: View>(isPresented: Binding<Bool>, anchor: CGRect = .zero,
                                         @ViewBuilder content: @escaping () -> PanelContent) -> some View {
        background(GeometryReader { geo in
            PickerPanelAnchor(isPresented: isPresented,
                              anchorInGlobal: pickerPanelGlobalAnchor(anchor, frame: geo.frame(in: .global),
                                                                      localSize: geo.size),
                              content: AnyView(content()))
        })
    }

}

/// `anchor` (local) mapped into the window's global space, honoring any scale applied above the
/// view (the UI zoom) — the global frame's size over the local size is that scale. Pure.
func pickerPanelGlobalAnchor(_ anchor: CGRect, frame: CGRect, localSize: CGSize) -> CGRect {
    guard anchor != .zero, localSize.width > 0, localSize.height > 0 else { return frame }
    let sx = frame.width / localSize.width, sy = frame.height / localSize.height
    return CGRect(x: frame.minX + anchor.minX * sx, y: frame.minY + anchor.minY * sy,
                  width: anchor.width * sx, height: anchor.height * sy)
}

private struct PickerPanelAnchor: NSViewRepresentable {
    @Binding var isPresented: Bool
    let anchorInGlobal: CGRect
    let content: AnyView

    func makeCoordinator() -> PickerPanelHost { PickerPanelHost() }
    func makeNSView(context: Context) -> NSView { NSView() }

    func updateNSView(_ view: NSView, context: Context) {
        let host = context.coordinator
        host.onDismiss = { isPresented = false }
        if isPresented, let window = view.window {
            host.show(content, anchorInGlobal: anchorInGlobal, parent: window)
        } else {
            host.hide()
        }
    }

    static func dismantleNSView(_ view: NSView, coordinator: PickerPanelHost) {
        coordinator.hide()
    }
}

@MainActor
final class PickerPanelHost {
    var onDismiss: (() -> Void)?
    private var panel: PickerPanelWindow?
    private var hosting: NSHostingView<AnyView>?
    private weak var parent: NSWindow?
    private var monitor: Any?
    private var observers: [NSObjectProtocol] = []

    func show(_ content: AnyView, anchorInGlobal: CGRect, parent: NSWindow) {
        let body = AnyView(content
            .padding(10)
            .background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color(white: 0.5, opacity: 0.4), lineWidth: 1)))
        if let hosting, let panel {
            hosting.rootView = body          // already open: just refresh (e.g. the 2nd monster)
            place(panel, size: hosting.fittingSize, anchorInGlobal: anchorInGlobal, parent: parent)
            return
        }
        let hosting = NSHostingView(rootView: body)
        let panel = PickerPanelWindow(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                                      backing: .buffered, defer: true)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .none
        panel.contentView = hosting
        place(panel, size: hosting.fittingSize, anchorInGlobal: anchorInGlobal, parent: parent)
        parent.addChildWindow(panel, ordered: .above)
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
        self.hosting = hosting
        self.parent = parent
        install()
    }

    func hide() {
        guard let panel else { return }
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        observers.forEach(NotificationCenter.default.removeObserver)
        observers = []
        parent?.removeChildWindow(panel)
        panel.orderOut(nil)
        self.panel = nil
        hosting = nil
        if let parent, parent.isVisible { parent.makeKey() }
    }

    private func dismiss() {
        hide()
        onDismiss?()
    }

    /// Esc, or a click anywhere outside the panel, closes it (the click is swallowed, as a
    /// transient popover's is); so does the app or panel losing focus.
    private func install() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown,
                                                              .otherMouseDown, .keyDown]) { [weak self] event in
            guard let self, let panel = self.panel else { return event }
            if event.type == .keyDown {
                if event.keyCode == 53 { self.dismiss(); return nil }   // Esc
                return event
            }
            if event.window === panel { return event }
            self.dismiss()
            return nil
        }
        let nc = NotificationCenter.default
        observers.append(nc.addObserver(forName: NSApplication.didResignActiveNotification, object: nil,
                                        queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.dismiss() }
        })
    }

    private func place(_ panel: NSWindow, size: CGSize, anchorInGlobal: CGRect, parent: NSWindow) {
        guard let contentView = parent.contentView else { return }
        // SwiftUI's global space is the window content, top-left origin.
        let h = contentView.bounds.height
        let inWindow = NSRect(x: anchorInGlobal.minX,
                              y: contentView.isFlipped ? anchorInGlobal.minY : h - anchorInGlobal.maxY,
                              width: anchorInGlobal.width, height: anchorInGlobal.height)
        let windowRect = contentView.isFlipped ? contentView.convert(inWindow, to: nil) : inWindow
        let anchorOnScreen = parent.convertToScreen(windowRect)
        let visible = parent.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .infinite
        panel.setFrame(Self.frame(size: size, anchor: anchorOnScreen, visible: visible), display: true)
    }

    /// Where the panel goes (screen coordinates, bottom-left origin): centered under the anchor,
    /// or above it when there's no room below, kept on screen. Pure.
    static func frame(size: CGSize, anchor: CGRect, visible: CGRect, gap: CGFloat = 4) -> CGRect {
        var y = anchor.minY - gap - size.height
        if y < visible.minY { y = anchor.maxY + gap }
        y = min(max(y, visible.minY), visible.maxY - size.height)
        let x = min(max(anchor.midX - size.width / 2, visible.minX), visible.maxX - size.width)
        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }
}

/// A borderless panel that can still take key (so its controls respond to the first click).
final class PickerPanelWindow: NSPanel {
    override var canBecomeKey: Bool { true }
}
