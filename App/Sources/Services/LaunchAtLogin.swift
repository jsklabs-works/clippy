import Foundation
import ServiceManagement

/// Login item via SMAppService, which works inside the App Sandbox and
/// needs no helper app.
enum LaunchAtLogin {
    static var isEnabled: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                NSLog("ClipStack: failed to update login item: \(error)")
            }
        }
    }
}
