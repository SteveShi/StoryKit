import SwiftUI

public struct AppCommands: Commands {
    @ObservedObject public var bridge: StoryKitBridge
    @Binding public var showWhatsNew: Bool

    public init(bridge: StoryKitBridge, showWhatsNew: Binding<Bool>) {
        self.bridge = bridge
        self._showWhatsNew = showWhatsNew
    }

    public var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button(String(localized: "storykit.menu.new_world")) {
                bridge.triggerNewWorld()
            }
            .keyboardShortcut("n", modifiers: .command)

            Button(String(localized: "storykit.menu.open")) {
                bridge.handleOpenFileDialog()
            }
            .keyboardShortcut("o", modifiers: .command)
        }

        CommandGroup(after: .saveItem) {
            Button(String(localized: "storykit.menu.save")) {
                bridge.triggerExportProject()
            }
            .keyboardShortcut("s", modifiers: .command)

            Divider()

            Menu(String(localized: "storykit.menu.export_map")) {
                Button(String(localized: "storykit.menu.export_png")) {
                    bridge.triggerExportMap(format: "png")
                }
                .keyboardShortcut("e", modifiers: .command)

                Button(String(localized: "storykit.menu.export_svg")) {
                    bridge.triggerExportMap(format: "svg")
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
            }
        }

        // Help Menu according to Apple HIG and project rules:
        // WhatsNewSheetView entry MUST be placed ONLY in the Help menu
        CommandGroup(replacing: .help) {
            Button(String(localized: "storykit.menu.whats_new")) {
                showWhatsNew = true
            }

            Divider()

            Link(
                String(localized: "storykit.menu.online_docs"),
                destination: URL(string: "https://github.com/Jannchie/cartographer")!
            )

            Link(
                String(localized: "storykit.menu.report_issue"),
                destination: URL(string: "https://github.com/Jannchie/cartographer/issues")!
            )
        }
    }
}
