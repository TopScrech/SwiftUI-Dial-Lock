import SwiftUI

@main
struct DialLockApp: App {
    @AppStorage("hideStatusBar") private var hideStatusBar = false
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                RotaryPasscodeLock()
            }
            .statusBar(hidden: hideStatusBar)
        }
    }
}
