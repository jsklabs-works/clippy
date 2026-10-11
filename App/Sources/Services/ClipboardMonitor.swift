import AppKit
import ClipCore

/// Watches the general pasteboard for changes.
///
/// macOS has no "pasteboard changed" notification, so like every clipboard
/// manager we poll `changeCount`. Reading the count is cheap; data is only
/// read when the count changes.
@MainActor
final class ClipboardMonitor {
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    private let onCapture: ([PasteboardEntry], String?) -> Void

    init(onCapture: @escaping ([PasteboardEntry], String?) -> Void) {
        self.onCapture = onCapture
        lastChangeCount = pasteboard.changeCount
    }

    func start() {
        timer?.invalidate()
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.poll() }
        }
        timer.tolerance = 0.2
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        let count = pasteboard.changeCount
        guard count != lastChangeCount else { return }
        lastChangeCount = count
        guard !Preferences.isPaused else { return }

        let rules = Preferences.captureRules
        let types = (pasteboard.types ?? []).map(\.rawValue)
        let source = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        guard rules.shouldInspect(types: types, sourceBundleID: source) else { return }

        var entries: [PasteboardEntry] = []
        for (index, item) in (pasteboard.pasteboardItems ?? []).enumerated() {
            for type in rules.storableTypes(item.types.map(\.rawValue)) {
                if let data = item.data(forType: NSPasteboard.PasteboardType(type)) {
                    entries.append(PasteboardEntry(itemIndex: index, type: type, data: data))
                }
            }
        }
        guard rules.shouldStore(entries) else { return }
        onCapture(entries, source)
    }
}
