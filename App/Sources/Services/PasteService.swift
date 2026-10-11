import AppKit
import ApplicationServices
import ClipCore

/// Puts history items back on the pasteboard and, optionally, pastes them
/// into the frontmost app.
@MainActor
enum PasteService {
    /// Added to everything we write so `ClipboardMonitor` doesn't record our
    /// own writes as new copies.
    nonisolated static let ownMarkerType = "com.jsklabs.ClipStack.internal"

    static func copy(_ item: HistoryItem, plainText: Bool) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        let marker = NSPasteboard.PasteboardType(ownMarkerType)
        if plainText, let text = item.searchText, item.kind == .text {
            let pbItem = NSPasteboardItem()
            pbItem.setString(text, forType: .string)
            pbItem.setData(Data(), forType: marker)
            pasteboard.writeObjects([pbItem])
            return
        }

        let grouped = Dictionary(grouping: item.entries, by: \.itemIndex)
        let pbItems = grouped.keys.sorted().map { index -> NSPasteboardItem in
            let pbItem = NSPasteboardItem()
            for entry in grouped[index] ?? [] {
                pbItem.setData(entry.data, forType: NSPasteboard.PasteboardType(entry.type))
            }
            return pbItem
        }
        pbItems.first?.setData(Data(), forType: marker)
        pasteboard.writeObjects(pbItems)
    }

    // MARK: Auto-paste

    /// Whether the user has granted Accessibility access, which macOS
    /// requires before an app may send keystrokes to other apps.
    static var canAutoPaste: Bool { AXIsProcessTrusted() }

    /// Shows the system prompt that sends the user to
    /// System Settings › Privacy & Security › Accessibility.
    static func requestAccessibility() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    /// Sends ⌘V to the frontmost app.
    static func pasteIntoFrontApp() {
        guard canAutoPaste else { return }
        let source = CGEventSource(stateID: .combinedSessionState)
        let vKey: CGKeyCode = 0x09 // kVK_ANSI_V
        let down = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true)
        let up = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: false)
        down?.flags = .maskCommand
        up?.flags = .maskCommand
        down?.post(tap: .cgSessionEventTap)
        up?.post(tap: .cgSessionEventTap)
    }
}
