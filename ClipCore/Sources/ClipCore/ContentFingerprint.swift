import Foundation

/// A stable key used to detect "the same thing copied again".
///
/// It hashes only the representations a user would see, not every type an
/// app adds. Copying the same sentence from Safari and from Notes produces
/// different HTML/RTF but the same plain text, and those copies should
/// collapse into one history row.
public enum ContentFingerprint {
    public static func make(_ entries: [PasteboardEntry]) -> String {
        let primary: [PasteboardEntry]
        switch entries.kind {
        case .file:
            primary = entries.filter { $0.type == PasteboardTypes.fileURL }
        case .text:
            primary = entries.filter { $0.type == PasteboardTypes.string }
        case .image:
            let type = PasteboardTypes.images.first { t in entries.contains { $0.type == t } }
            primary = entries.filter { $0.type == type }
        case .other:
            primary = entries
        }

        var hasher = FNV1a()
        hasher.mix(entries.kind.rawValue.utf8)
        for entry in primary.sorted(by: { ($0.itemIndex, $0.type) < ($1.itemIndex, $1.type) }) {
            hasher.mix(String(entry.itemIndex).utf8)
            hasher.mix([0])
            hasher.mix(entry.type.utf8)
            hasher.mix([0])
            hasher.mix(String(entry.data.count).utf8)
            hasher.mix([0])
            hasher.mix(entry.data)
        }
        let hex = String(hasher.value, radix: 16)
        return String(repeating: "0", count: 16 - hex.count) + hex
    }
}

/// 64-bit FNV-1a. Not cryptographic; it only keys history rows, and a
/// collision would merely merge two rows.
struct FNV1a {
    private(set) var value: UInt64 = 0xcbf2_9ce4_8422_2325

    mutating func mix<S: Sequence>(_ bytes: S) where S.Element == UInt8 {
        for byte in bytes {
            value ^= UInt64(byte)
            value = value &* 0x0000_0100_0000_01b3
        }
    }
}
