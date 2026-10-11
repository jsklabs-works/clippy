import AppKit
import SwiftUI

/// A floating, non-activating panel that hosts the history list.
///
/// "Non-activating" is the key trick: the panel takes keyboard focus for
/// the search field, but the app you were typing in stays the active app,
/// so ⌘V lands there without having to switch apps back.
final class PopupPanel: NSPanel {
    var onClose: (() -> Void)?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 480),
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView, .resizable],
            backing: .buffered,
            defer: true
        )
        isFloatingPanel = true
        level = .popUpMenu
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        animationBehavior = .utilityWindow
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Clicking anywhere else dismisses the popup, like a menu.
    override func resignKey() {
        super.resignKey()
        close()
    }

    // super.close() resigns key, which calls close() again.
    private var isClosing = false

    override func close() {
        guard isVisible, !isClosing else { return }
        isClosing = true
        defer { isClosing = false }
        super.close()
        onClose?()
    }

    override func cancelOperation(_ sender: Any?) {
        close()
    }

    /// Positions the panel at the mouse pointer, kept fully on screen.
    func show(near point: NSPoint) {
        let screen = NSScreen.screens.first { NSMouseInRect(point, $0.frame, false) } ?? NSScreen.main
        var origin = NSPoint(x: point.x, y: point.y - frame.height)
        if let visible = screen?.visibleFrame {
            origin.x = min(max(origin.x, visible.minX), visible.maxX - frame.width)
            origin.y = min(max(origin.y, visible.minY), visible.maxY - frame.height)
        }
        setFrameOrigin(origin)
        makeKeyAndOrderFront(nil)
    }
}
