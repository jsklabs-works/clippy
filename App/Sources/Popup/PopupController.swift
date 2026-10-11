import AppKit
import SwiftUI

/// Shows and hides the history popup and carries out what the user picks.
@MainActor
final class PopupController {
    private let store: HistoryStore
    private let panel = PopupPanel()

    init(store: HistoryStore) {
        self.store = store
    }

    var isVisible: Bool { panel.isVisible }

    func toggle() {
        isVisible ? panel.close() : show(at: NSEvent.mouseLocation)
    }

    /// Shows the popup with its top-left corner at `point` (screen coords).
    func show(at point: NSPoint) {
        // A fresh view each time resets the search text and selection.
        let view = HistoryView(actions: HistoryActions(
            select: { [weak self] item, plain in self?.select(item, plainText: plain) },
            togglePin: { [weak self] item in self?.store.togglePin(item) },
            delete: { [weak self] item in self?.store.delete(item) },
            close: { [weak self] in self?.panel.close() }
        ))
        .modelContainer(store.container)
        panel.contentView = NSHostingView(rootView: view)
        panel.show(near: point)
    }

    private func select(_ item: HistoryItem, plainText: Bool) {
        PasteService.copy(item, plainText: plainText || Preferences.pastePlainText)
        store.touch(item)
        panel.close()

        guard Preferences.autoPaste else { return }
        // Give the target app a moment to regain key focus after the
        // panel closes, then paste.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            PasteService.pasteIntoFrontApp()
        }
    }
}

struct HistoryActions {
    var select: (HistoryItem, _ plainText: Bool) -> Void
    var togglePin: (HistoryItem) -> Void
    var delete: (HistoryItem) -> Void
    var close: () -> Void
}
