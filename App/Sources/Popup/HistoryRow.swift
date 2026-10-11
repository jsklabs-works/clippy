import AppKit
import ClipCore
import SwiftUI

struct HistoryRow: View {
    let item: HistoryItem
    let index: Int
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            icon
                .frame(width: 28, height: 28)
            Text(item.title)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 4)
            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if index < 9 {
                Text("⌘\(index + 1)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.25) : .clear)
        )
        .help(item.searchText.map { String($0.prefix(1_000)) } ?? item.title)
    }

    @ViewBuilder
    private var icon: some View {
        switch item.kind {
        case .image:
            if let image = Thumbnails.image(for: item) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(systemName: "photo")
            }
        case .file:
            if let url = item.entries.fileURLs.first {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable()
            } else {
                Image(systemName: "doc")
            }
        case .text:
            Image(systemName: "text.alignleft").foregroundStyle(.secondary)
        case .other:
            Image(systemName: "questionmark.square.dashed").foregroundStyle(.secondary)
        }
    }
}

/// Decoding a full image on every redraw would make scrolling stutter, so
/// row thumbnails are cached by content fingerprint.
@MainActor
enum Thumbnails {
    private static let cache = NSCache<NSString, NSImage>()

    static func image(for item: HistoryItem) -> NSImage? {
        let key = item.fingerprint as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let data = item.entries.imageData, let image = NSImage(data: data) else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }
}
