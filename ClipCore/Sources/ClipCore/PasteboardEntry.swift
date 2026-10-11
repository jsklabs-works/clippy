import Foundation

/// One typed representation copied from the pasteboard.
///
/// A single copy can contain several pasteboard items (e.g. copying three
/// files in Finder) and each item can carry several types (plain text, RTF,
/// HTML…). `itemIndex` records which item a representation belongs to so the
/// copy can be restored exactly.
public struct PasteboardEntry: Codable, Hashable, Sendable {
    public var itemIndex: Int
    public var type: String
    public var data: Data

    public init(itemIndex: Int, type: String, data: Data) {
        self.itemIndex = itemIndex
        self.type = type
        self.data = data
    }
}

/// Uniform Type Identifiers used by the pasteboard. Kept as raw strings so
/// this module doesn't depend on AppKit.
public enum PasteboardTypes {
    public static let string = "public.utf8-plain-text"
    public static let fileURL = "public.file-url"
    public static let rtf = "public.rtf"
    public static let html = "public.html"
    public static let png = "public.png"
    public static let tiff = "public.tiff"
    public static let jpeg = "public.jpeg"
    public static let heic = "public.heic"

    public static let images: [String] = [png, tiff, jpeg, heic]
}

public enum ClipKind: String, Codable, Sendable {
    case text, image, file, other
}

public extension Array where Element == PasteboardEntry {
    func firstData(ofType type: String) -> Data? {
        first { $0.type == type }?.data
    }

    /// The plain-text representation, if any item carries one.
    var plainText: String? {
        firstData(ofType: PasteboardTypes.string).flatMap { String(data: $0, encoding: .utf8) }
    }

    /// All file URLs, one per pasteboard item.
    var fileURLs: [URL] {
        filter { $0.type == PasteboardTypes.fileURL }
            .compactMap { String(data: $0.data, encoding: .utf8) }
            .compactMap { URL(string: $0) }
    }

    var imageData: Data? {
        for type in PasteboardTypes.images {
            if let data = firstData(ofType: type) { return data }
        }
        return nil
    }

    var kind: ClipKind {
        if !fileURLs.isEmpty { return .file }
        if plainText != nil { return .text }
        if imageData != nil { return .image }
        return .other
    }

    var totalBytes: Int {
        reduce(0) { $0 + $1.data.count }
    }
}
