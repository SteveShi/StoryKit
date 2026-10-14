import SwiftUI

@main
struct StoryKitApp: App {
    @StateObject private var bridge = StoryKitBridge()
    @State private var showWhatsNew = false

    var body: some Scene {
        WindowGroup {
            ContentView(bridge: bridge)
                .frame(minWidth: 960, minHeight: 640)
                .sheet(isPresented: $showWhatsNew) {
                    WhatsNewSheetView()
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            AppCommands(bridge: bridge, showWhatsNew: $showWhatsNew)
        }

        Settings {
            SettingsView(bridge: bridge)
        }
    }
}
