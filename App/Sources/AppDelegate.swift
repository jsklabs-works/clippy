import AppKit
import KeyboardShortcuts
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) lazy var store = HistoryStore()
    private lazy var popup = PopupController(store: store)
    private lazy var monitor = ClipboardMonitor { [weak self] entries, source in
        self?.store.add(entries, sourceApp: source)
    }
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Preferences.registerDefaults()
        setUpStatusItem()
        KeyboardShortcuts.onKeyUp(for: .togglePopup) { [weak self] in
            self?.popup.toggle()
        }
        monitor.start()
        if !Preferences.hasCompletedOnboarding {
            showOnboarding()
        }
    }

    // MARK: Menu bar

    private func setUpStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clippy")
        item.button?.target = self
        item.button?.action = #selector(statusItemClicked(_:))
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        item.button?.appearsDisabled = Preferences.isPaused
        statusItem = item
    }

    /// Left click opens history under the icon; right click shows the menu.
    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showMenu()
            return
        }
        guard let window = sender.window else { return }
        let frame = window.convertToScreen(sender.convert(sender.bounds, to: nil))
        popup.isVisible ? popup.toggle() : popup.show(at: NSPoint(x: frame.minX, y: frame.minY - 4))
    }

    private func showMenu() {
        let menu = NSMenu()
        let pause = NSMenuItem(title: Preferences.isPaused ? "Resume Recording" : "Pause Recording",
                               action: #selector(togglePaused), keyEquivalent: "")
        menu.addItem(pause)
        menu.addItem(NSMenuItem(title: "Clear History (Keep Pinned)", action: #selector(clearHistory), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Quit Clippy", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        for item in menu.items where item.action != #selector(NSApplication.terminate(_:)) {
            item.target = self
        }
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        // Detach so the next left click goes back to the popup.
        statusItem?.menu = nil
    }

    @objc private func togglePaused() {
        UserDefaults.standard.set(!Preferences.isPaused, forKey: Preferences.isPausedKey)
        statusItem?.button?.appearsDisabled = Preferences.isPaused
    }

    @objc private func clearHistory() {
        store.clear(includingPinned: false)
    }

    // MARK: Windows

    /// Marked as seen up front, so closing the window with its close button
    /// also counts and it never nags on later launches.
    private func showOnboarding() {
        UserDefaults.standard.set(true, forKey: Preferences.hasCompletedOnboardingKey)
        let window = NSWindow(contentViewController: NSHostingController(
            rootView: OnboardingView { [weak self] in
                self?.onboardingWindow?.close()
                self?.onboardingWindow = nil
            }
        ))
        window.title = ""
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.center()
        onboardingWindow = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    /// A menu-bar-only app has no app menu, and SwiftUI's Settings scene
    /// can't be opened reliably from AppKit code, so the window is managed
    /// here.
    @objc func openSettings() {
        if settingsWindow == nil {
            let window = NSWindow(contentViewController: NSHostingController(
                rootView: SettingsView(store: store)
            ))
            window.title = "Clippy Settings"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}
