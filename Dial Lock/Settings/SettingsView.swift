import SwiftUI

struct SettingsView: View {
    @AppStorage("hideStatusBar") private var hideStatusBar = false

    var body: some View {
        List {
            Toggle("Hide Status Bar", isOn: $hideStatusBar)
        }
    }
}

#Preview {
    SettingsView()
}
