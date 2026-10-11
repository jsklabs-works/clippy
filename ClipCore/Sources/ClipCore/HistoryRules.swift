import Foundation

public struct TrimCandidate<ID: Hashable>: Sendable where ID: Sendable {
    public var id: ID
    public var isPinned: Bool
    public var lastCopiedAt: Date

    public init(id: ID, isPinned: Bool, lastCopiedAt: Date) {
        self.id = id
        self.isPinned = isPinned
        self.lastCopiedAt = lastCopiedAt
    }
}

public enum HistoryTrimmer {
    /// IDs to delete so that at most `limit` unpinned items remain. Pinned
    /// items are never removed and don't count toward the limit.
    public static func idsToRemove<ID>(_ items: [TrimCandidate<ID>], limit: Int) -> [ID] {
        let unpinned = items
            .filter { !$0.isPinned }
            .sorted { $0.lastCopiedAt > $1.lastCopiedAt }
        return unpinned.dropFirst(max(limit, 0)).map(\.id)
    }
}

public enum ClipTitle {
    /// A one-line label for a history row: whitespace runs (including
    /// newlines) collapse to single spaces, and long text is cut with "…".
    public static func make(from text: String, maxLength: Int = 200) -> String? {
        let collapsed = text
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
        guard !collapsed.isEmpty else { return nil }
        guard collapsed.count > maxLength else { return collapsed }
        return String(collapsed.prefix(maxLength - 1)) + "…"
    }

    /// The title for any copy, falling back by kind.
    public static func make(for entries: [PasteboardEntry]) -> String {
        switch entries.kind {
        case .file:
            let names = entries.fileURLs.map(\.lastPathComponent)
            return make(from: names.joined(separator: ", ")) ?? "Files"
        case .text:
            return make(from: entries.plainText ?? "") ?? "(whitespace)"
        case .image:
            return "Image"
        case .other:
            return entries.first?.type ?? "Unknown"
        }
    }
}
