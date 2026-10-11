import ClipCore
import Foundation
import KeyboardShortcuts

/// UserDefaults keys. Views read these with @AppStorage; services read them
/// through the accessors below.
enum Preferences {
    static let historySizeKey = "historySize"
    static let autoPasteKey = "autoPaste"
    static let pastePlainTextKey = "pastePlainText"
    static let ignoredAppsKey = "ignoredApps"
    static let isPausedKey = "isPaused"
    static let hasCompletedOnboardingKey = "hasCompletedOnboarding"

    static let defaultHistorySize = 200

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            historySizeKey: defaultHistorySize,
            autoPasteKey: false,
            pastePlainTextKey: false,
            ignoredAppsKey: "",
            isPausedKey: false,
            hasCompletedOnboardingKey: false,
        ])
    }

    static var historySize: Int { UserDefaults.standard.integer(forKey: historySizeKey) }
    static var autoPaste: Bool { UserDefaults.standard.bool(forKey: autoPasteKey) }
    static var pastePlainText: Bool { UserDefaults.standard.bool(forKey: pastePlainTextKey) }
    static var isPaused: Bool { UserDefaults.standard.bool(forKey: isPausedKey) }
    static var hasCompletedOnboarding: Bool { UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey) }

    /// User-added bundle IDs, one per line.
    static var ignoredApps: Set<String> {
        let raw = UserDefaults.standard.string(forKey: ignoredAppsKey) ?? ""
        return Set(raw.split(whereSeparator: \.isNewline).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })
    }

    static var captureRules: CaptureRules {
        CaptureRules(
            ignoredApps: CaptureRules.defaultIgnoredApps.union(ignoredApps),
            ownMarkerType: PasteService.ownMarkerType
        )
    }
}

extension KeyboardShortcuts.Name {
    /// ⇧⌘C by default, the same as Maccy.
    static let togglePopup = Self("togglePopup", default: .init(.c, modifiers: [.command, .shift]))
}
