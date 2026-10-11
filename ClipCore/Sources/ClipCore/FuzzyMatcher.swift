import Foundation

/// Search used by the popup. A query matches when all of its characters
/// appear in order (case-insensitively). Contiguous substrings rank above
/// scattered matches, and earlier matches rank above later ones.
public enum FuzzyMatcher {
    /// Only this much of each item is searched, so a giant copied log file
    /// can't stall typing.
    public static let searchLimit = 5_000

    /// Returns nil when `query` doesn't match `text`. Higher is better.
    public static func score(_ query: String, in text: String) -> Int? {
        let needle = Array(query.lowercased())
        if needle.isEmpty { return 0 }
        let haystack = Array(text.prefix(searchLimit).lowercased())
        if needle.count > haystack.count { return nil }

        if let start = indexOfSubstring(needle, in: haystack) {
            let wordStart = start == 0 || isBoundary(haystack[start - 1])
            return 10_000 - min(start, 5_000) + (wordStart ? 1_000 : 0)
        }

        var score = 0
        var lastMatch = -2
        var cursor = 0
        for char in needle {
            guard let found = haystack[cursor...].firstIndex(of: char) else { return nil }
            if found == lastMatch + 1 {
                score += 15
            } else if found == 0 || isBoundary(haystack[found - 1]) {
                score += 10
            } else {
                score += 1
            }
            lastMatch = found
            cursor = found + 1
        }
        return score
    }

    /// Filters and orders `items`. Ties keep their input order, so callers
    /// pass items already sorted by pin state and recency.
    public static func rank<T>(_ items: [T], query: String, text: (T) -> String) -> [T] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return items }
        return items.enumerated()
            .compactMap { offset, item in score(trimmed, in: text(item)).map { (offset, $0, item) } }
            .sorted { $0.1 != $1.1 ? $0.1 > $1.1 : $0.0 < $1.0 }
            .map { $0.2 }
    }

    private static func indexOfSubstring(_ needle: [Character], in haystack: [Character]) -> Int? {
        guard needle.count <= haystack.count else { return nil }
        for start in 0...(haystack.count - needle.count)
        where haystack[start] == needle[0] && Array(haystack[start..<start + needle.count]) == needle {
            return start
        }
        return nil
    }

    private static func isBoundary(_ char: Character) -> Bool {
        !(char.isLetter || char.isNumber)
    }
}
