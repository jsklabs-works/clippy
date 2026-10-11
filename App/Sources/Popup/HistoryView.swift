import ClipCore
import SwiftData
import SwiftUI

/// The popup's content: a search field over the history list.
///
/// Keys: ↑/↓ move, ⏎ pastes, ⌥⏎ pastes as plain text, ⌘1–⌘9 paste the
/// numbered rows, ⌘P pins, ⌘⌫ deletes, Esc closes.
struct HistoryView: View {
    let actions: HistoryActions

    @Query(sort: \HistoryItem.lastCopiedAt, order: .reverse) private var items: [HistoryItem]
    @State private var query = ""
    @State private var selectedIndex = 0
    @FocusState private var searchFocused: Bool

    /// Pinned items first, then by recency; search re-ranks by relevance.
    private var visibleItems: [HistoryItem] {
        let ordered = items.filter(\.isPinned) + items.filter { !$0.isPinned }
        return FuzzyMatcher.rank(ordered, query: query) { $0.searchText ?? $0.title }
    }

    var body: some View {
        let visible = visibleItems
        VStack(spacing: 0) {
            searchField(visible)
            Divider()
            if visible.isEmpty {
                emptyState
            } else {
                list(visible)
            }
            Divider()
            footer
        }
        .frame(minWidth: 320, minHeight: 240)
        .background(.regularMaterial)
        .onAppear { searchFocused = true }
        .onChange(of: query) { selectedIndex = 0 }
    }

    private func searchField(_ visible: [HistoryItem]) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Search clipboard history", text: $query)
                .textFieldStyle(.plain)
                .font(.title3)
                .focused($searchFocused)
                .onKeyPress(phases: .down) { press in handleKey(press, visible: visible) }
        }
        .padding(.horizontal, 12)
        .padding(.top, 28) // clears the hidden title bar
        .padding(.bottom, 10)
    }

    private func list(_ visible: [HistoryItem]) -> some View {
        ScrollViewReader { proxy in
            List {
                ForEach(Array(visible.enumerated()), id: \.element.persistentModelID) { index, item in
                    HistoryRow(item: item, index: index, isSelected: index == selectedIndex)
                        .id(index)
                        .contentShape(Rectangle())
                        .onTapGesture { actions.select(item, false) }
                        .contextMenu {
                            Button("Paste") { actions.select(item, false) }
                            Button("Paste as Plain Text") { actions.select(item, true) }
                                .disabled(item.kind != .text)
                            Button(item.isPinned ? "Unpin" : "Pin") { actions.togglePin(item) }
                            Divider()
                            Button("Delete", role: .destructive) { actions.delete(item) }
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .onChange(of: selectedIndex) { _, index in
                proxy.scrollTo(index)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Spacer()
            Image(systemName: "doc.on.clipboard").font(.largeTitle).foregroundStyle(.tertiary)
            Text(query.isEmpty ? "Copy something to get started" : "No matches")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var footer: some View {
        HStack {
            Text("⏎ paste   ⌥⏎ plain text   ⌘P pin   ⌘⌫ delete")
            Spacer()
            Text("\(items.count) items")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private func handleKey(_ press: KeyPress, visible: [HistoryItem]) -> KeyPress.Result {
        let selected = visible.indices.contains(selectedIndex) ? visible[selectedIndex] : nil

        switch press.key {
        case .downArrow:
            selectedIndex = min(selectedIndex + 1, max(visible.count - 1, 0))
            return .handled
        case .upArrow:
            selectedIndex = max(selectedIndex - 1, 0)
            return .handled
        case .return:
            guard let selected else { return .handled }
            actions.select(selected, press.modifiers.contains(.option))
            return .handled
        case .escape:
            actions.close()
            return .handled
        case .delete where press.modifiers.contains(.command):
            if let selected { actions.delete(selected) }
            return .handled
        default:
            break
        }

        guard press.modifiers.contains(.command) else { return .ignored }
        if press.characters == "p", let selected {
            actions.togglePin(selected)
            return .handled
        }
        if let digit = Int(press.characters), (1...9).contains(digit), visible.indices.contains(digit - 1) {
            actions.select(visible[digit - 1], press.modifiers.contains(.option))
            return .handled
        }
        return .ignored
    }
}
