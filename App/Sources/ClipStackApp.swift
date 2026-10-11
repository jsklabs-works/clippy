import SwiftUI

@main
struct ClipStackApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // The app lives in the menu bar (LSUIElement) and manages its own
        // windows in AppDelegate. SwiftUI still requires one scene.
        Settings {
            EmptyView()
        }
    }
}
