import ClipCore
import Foundation
import SwiftData

/// Writes to the history database. Views read it directly with @Query.
@MainActor
final class HistoryStore {
    let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    init() {
        do {
            container = try ModelContainer(for: HistoryItem.self)
        } catch {
            // A corrupt store shouldn't brick the app: fall back to an
            // in-memory history for this launch.
            NSLog("ClipStack: failed to open history store: \(error)")
            container = try! ModelContainer(for: HistoryItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        }
    }

    func add(_ entries: [PasteboardEntry], sourceApp: String?) {
        let fingerprint = ContentFingerprint.make(entries)
        let descriptor = FetchDescriptor<HistoryItem>(predicate: #Predicate { $0.fingerprint == fingerprint })
        if let existing = try? context.fetch(descriptor).first {
            existing.recordCopy(entries: entries, sourceApp: sourceApp)
        } else {
            context.insert(HistoryItem(entries: entries, sourceApp: sourceApp))
        }
        trim()
    }

    /// Moves an item to the top after it's pasted from history.
    func touch(_ item: HistoryItem) {
        item.lastCopiedAt = .now
        item.numberOfCopies += 1
        save()
    }

    func togglePin(_ item: HistoryItem) {
        item.isPinned.toggle()
        trim()
    }

    func delete(_ item: HistoryItem) {
        context.delete(item)
        save()
    }

    func clear(includingPinned: Bool) {
        let all = (try? context.fetch(FetchDescriptor<HistoryItem>())) ?? []
        for item in all where includingPinned || !item.isPinned {
            context.delete(item)
        }
        save()
    }

    /// Applies the history size limit, e.g. after the user lowers it.
    func trim() {
        removeOverflow()
        save()
    }

    private func removeOverflow() {
        let all = (try? context.fetch(FetchDescriptor<HistoryItem>())) ?? []
        let candidates = all.map { TrimCandidate(id: $0.persistentModelID, isPinned: $0.isPinned, lastCopiedAt: $0.lastCopiedAt) }
        let doomed = Set(HistoryTrimmer.idsToRemove(candidates, limit: Preferences.historySize))
        for item in all where doomed.contains(item.persistentModelID) {
            context.delete(item)
        }
    }

    private func save() {
        do {
            try context.save()
        } catch {
            NSLog("ClipStack: failed to save history: \(error)")
        }
    }
}
