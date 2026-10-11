import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    let store: HistoryStore

    @AppStorage(Preferences.historySizeKey) private var historySize = Preferences.defaultHistorySize
    @AppStorage(Preferences.autoPasteKey) private var autoPaste = false
    @AppStorage(Preferences.pastePlainTextKey) private var pastePlainText = false
    @AppStorage(Preferences.ignoredAppsKey) private var ignoredApps = ""
    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var hasAccessibility = PasteService.canAutoPaste
    @State private var confirmClear = false

    var body: some View {
        TabView {
            general.tabItem { Label("General", systemImage: "gearshape") }
            privacy.tabItem { Label("Privacy", systemImage: "hand.raised") }
        }
        .frame(width: 460)
        .padding()
    }

    private var general: some View {
        Form {
            KeyboardShortcuts.Recorder("Open history:", name: .togglePopup)

            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, value in LaunchAtLogin.isEnabled = value }

            Stepper("Remember \(historySize) items", value: $historySize, in: 10...2_000, step: 10)
                .onChange(of: historySize) { store.trim() }

            Toggle("Always paste as plain text", isOn: $pastePlainText)

            Toggle("Paste automatically after choosing an item", isOn: $autoPaste)
                .onChange(of: autoPaste) { _, value in
                    if value && !PasteService.canAutoPaste { PasteService.requestAccessibility() }
                }
            if autoPaste && !hasAccessibility {
                HStack {
                    Text("Needs Accessibility access in System Settings › Privacy & Security.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Check Again") { hasAccessibility = PasteService.canAutoPaste }
                }
            }
        }
    }

    private var privacy: some View {
        Form {
            Section {
                TextEditor(text: $ignoredApps)
                    .font(.body.monospaced())
                    .frame(height: 100)
            } header: {
                Text("Don't record copies from these apps (bundle IDs, one per line)")
            } footer: {
                Text("Password managers and anything marked as concealed are always ignored.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Clear All History…", role: .destructive) { confirmClear = true }
                    .confirmationDialog("Delete all clipboard history, including pinned items?",
                                        isPresented: $confirmClear) {
                        Button("Clear All", role: .destructive) { store.clear(includingPinned: true) }
                    }
                Text("History is stored only on this Mac and is never sent anywhere.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
