import AppKit
import KeyboardShortcuts
import SwiftUI

/// Shown once on first launch. A menu-bar app has no window of its own, so
/// without this a new user could launch it and see nothing happen.
struct OnboardingView: View {
    let onFinish: () -> Void

    @AppStorage(Preferences.autoPasteKey) private var autoPaste = false
    @State private var launchAtLogin = LaunchAtLogin.isEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 14) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome to Clippy").font(.title2.bold())
                    Text("Everything you copy, one shortcut away.")
                        .foregroundStyle(.secondary)
                }
            }

            step(icon: "menubar.rectangle",
                 title: "It lives in your menu bar",
                 detail: "Look for the clipboard icon at the top of your screen. Right-click it for settings.")

            step(icon: "keyboard",
                 title: "Open your history from anywhere",
                 detail: "Search, then press Return to paste.") {
                KeyboardShortcuts.Recorder("Shortcut:", name: .togglePopup)
            }

            step(icon: "arrow.down.doc",
                 title: "Paste automatically (optional)",
                 detail: "Without this, choosing an item copies it and you press ⌘V yourself. With it, Clippy pastes for you, which needs Accessibility access.") {
                Toggle("Paste automatically", isOn: $autoPaste)
                    .onChange(of: autoPaste) { _, value in
                        if value && !PasteService.canAutoPaste { PasteService.requestAccessibility() }
                    }
            }

            step(icon: "power",
                 title: "Start with your Mac",
                 detail: "Keep your history available after a restart.") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, value in LaunchAtLogin.isEnabled = value }
            }

            HStack {
                Text("Password managers are ignored, and history never leaves this Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Get Started", action: onFinish)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(28)
        .frame(width: 520)
    }

    private func step(icon: String, title: String, detail: String) -> some View {
        step(icon: icon, title: title, detail: detail) { EmptyView() }
    }

    private func step<Control: View>(icon: String, title: String, detail: String,
                                     @ViewBuilder control: () -> Control) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.headline)
                Text(detail)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                control()
            }
        }
    }
}
