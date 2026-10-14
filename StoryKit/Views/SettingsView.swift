import SwiftUI
import AppKit

public struct SettingsView: View {
    @ObservedObject public var bridge: StoryKitBridge

    @AppStorage("atlasStyle") private var atlasStyle = "physical"
    @AppStorage("locale") private var locale = "zh-CN"
    @AppStorage("quality") private var quality = "high"
    @AppStorage("dayCycle") private var dayCycle = false
    @AppStorage("shadowSoftness") private var shadowSoftness = 3.0
    @AppStorage("defaultExportFormat") private var defaultExportFormat = "png"
    @AppStorage("defaultExportDirectory") private var defaultExportDirectory = ""

    public init(bridge: StoryKitBridge) {
        self.bridge = bridge
    }

    public var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label(String(localized: "storykit.settings.tab.general"), systemImage: "map")
                }

            graphicsTab
                .tabItem {
                    Label(String(localized: "storykit.settings.tab.graphics"), systemImage: "cube.transparent")
                }

            exportTab
                .tabItem {
                    Label(String(localized: "storykit.settings.tab.export"), systemImage: "arrow.down.doc")
                }
        }
        .frame(width: 480, height: 320)
        .padding(20)
        .onChange(of: atlasStyle) { bridge.syncPreferences() }
        .onChange(of: locale) { bridge.syncPreferences() }
        .onChange(of: quality) { bridge.syncPreferences() }
        .onChange(of: dayCycle) { bridge.syncPreferences() }
        .onChange(of: shadowSoftness) { bridge.syncPreferences() }
    }

    // MARK: - General Tab
    private var generalTab: some View {
        Form {
            Picker(String(localized: "storykit.settings.default_style"), selection: $atlasStyle) {
                Text(String(localized: "storykit.style.physical")).tag("physical")
                Text(String(localized: "storykit.style.fantasy")).tag("fantasy")
                Text(String(localized: "storykit.style.nautical")).tag("nautical")
                Text(String(localized: "storykit.style.teyvat")).tag("teyvat")
                Text(String(localized: "storykit.style.ink")).tag("ink")
                Text(String(localized: "storykit.style.topo")).tag("topo")
            }

            Picker(String(localized: "storykit.settings.language"), selection: $locale) {
                Text("简体中文").tag("zh-CN")
                Text("English").tag("en")
                Text("日本語").tag("ja")
            }

            Picker(String(localized: "storykit.settings.default_format"), selection: $defaultExportFormat) {
                Text("PNG (Raster)").tag("png")
                Text("SVG (Vector)").tag("svg")
            }
        }
    }

    // MARK: - Graphics Tab
    private var graphicsTab: some View {
        Form {
            Picker(String(localized: "storykit.settings.quality"), selection: $quality) {
                Text(String(localized: "storykit.quality.high")).tag("high")
                Text(String(localized: "storykit.quality.medium")).tag("medium")
                Text(String(localized: "storykit.quality.low")).tag("low")
            }

            Toggle(String(localized: "storykit.settings.day_cycle"), isOn: $dayCycle)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(String(localized: "storykit.settings.shadow_softness"))
                    Spacer()
                    Text(String(format: "%.0f", shadowSoftness))
                        .foregroundColor(.secondary)
                }
                Slider(value: $shadowSoftness, in: 1...5, step: 1)
            }
        }
    }

    // MARK: - Export Tab
    private var exportTab: some View {
        Form {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "storykit.settings.export_directory"))
                    .font(.headline)

                HStack {
                    TextField(
                        String(localized: "storykit.settings.export_directory_placeholder"),
                        text: $defaultExportDirectory
                    )
                    .textFieldStyle(.roundedBorder)

                    Button(String(localized: "storykit.settings.choose_button")) {
                        chooseExportDirectory()
                    }
                }

                if !defaultExportDirectory.isEmpty {
                    Button(String(localized: "storykit.settings.clear_button")) {
                        defaultExportDirectory = ""
                    }
                    .font(.footnote)
                }
            }
        }
    }

    private func chooseExportDirectory() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.canCreateDirectories = true

        if openPanel.runModal() == .OK, let selectedURL = openPanel.url {
            defaultExportDirectory = selectedURL.path
        }
    }
}
