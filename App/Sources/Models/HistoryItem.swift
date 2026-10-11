import ClipCore
import Foundation
import SwiftData

/// One row of clipboard history.
@Model
final class HistoryItem {
    /// Dedupe key from `ContentFingerprint`. Copying the same content again
    /// updates this row instead of adding a new one.
    @Attribute(.unique) var fingerprint: String
    var title: String
    /// Plain text used for search; nil for images.
    var searchText: String?
    var kindRaw: String
    /// Bundle ID of the app that was frontmost when this was copied.
    var sourceApp: String?
    var firstCopiedAt: Date
    var lastCopiedAt: Date
    var numberOfCopies: Int
    var isPinned: Bool
    /// Property-list-encoded `[PasteboardEntry]`. Stored outside the SQLite
    /// file because images can be large.
    @Attribute(.externalStorage) var payload: Data

    init(entries: [PasteboardEntry], sourceApp: String?, date: Date = .now) {
        fingerprint = ContentFingerprint.make(entries)
        title = ClipTitle.make(for: entries)
        searchText = entries.plainText ?? (entries.kind == .file ? entries.fileURLs.map(\.path).joined(separator: "\n") : nil)
        kindRaw = entries.kind.rawValue
        self.sourceApp = sourceApp
        firstCopiedAt = date
        lastCopiedAt = date
        numberOfCopies = 1
        isPinned = false
        payload = Self.encode(entries)
    }

    var kind: ClipKind { ClipKind(rawValue: kindRaw) ?? .other }

    var entries: [PasteboardEntry] {
        (try? PropertyListDecoder().decode([PasteboardEntry].self, from: payload)) ?? []
    }

    /// Records another copy of the same content, keeping the newest
    /// representations (e.g. fresher rich-text formatting).
    func recordCopy(entries: [PasteboardEntry], sourceApp: String?, date: Date = .now) {
        lastCopiedAt = date
        numberOfCopies += 1
        self.sourceApp = sourceApp
        payload = Self.encode(entries)
    }

    static func encode(_ entries: [PasteboardEntry]) -> Data {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        return (try? encoder.encode(entries)) ?? Data()
    }
}
