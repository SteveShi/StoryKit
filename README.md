# StoryKit

[简体中文](README.zh-CN.md) · English

**StoryKit** is a native macOS application for procedural fictional world and map generation, powered by Swift 6, SwiftUI, and [Jannchie/cartographer](https://github.com/Jannchie/cartographer).

<p align="center">
  <img src="web/cartographer/docs/images/en/world-3d.webp" alt="StoryKit 3D Diorama" width="90%">
</p>

## Highlights

- **Native macOS Experience**: Built with Swift 6.0 and SwiftUI. Features native menus, keyboard shortcuts (`⌘N`, `⌘O`, `⌘S`, `⌘E`), `NSSavePanel` / `NSOpenPanel` file interactions, and macOS Dark Mode.
- **Offline & Private**: Built-in `storykit://app/` custom scheme handler loads assets without network dependencies, avoiding browser security restrictions and firewall prompts.
- **Procedural World Generation**:
  - **Tectonics & Erosion**: Plate collision, stream-power valley erosion, windward precipitation, and Priority-Flood drainage networks.
  - **Four Historic Settlement Cultures**: Continuous town expansion with procedural street plans and landmarks across Western, Chinese, Japanese, and Islamic traditions.
  - **Diverse Map Styles**: Physical, Fantasy, Nautical, Teyvat, Ink Wash, and Topographic styles, alongside 3D dioramas with volumetric clouds and hologram projection tables.
- **Zero-Friction Upstream Sync**: Core algorithms are managed via Git Submodule. Updates from the upstream repository can be merged cleanly with a single command.
- **Strict Architecture**: 100% localized with `Localizable.xcstrings` (English & Simplified Chinese), functional settings panel, and native release highlight sheets.

## Architecture

```
StoryKit/
├── project.yml                          # XcodeGen definition
├── Scripts/
│   ├── sync-web.sh                      # Builds and copies web dist to Resources/web
│   └── generate-icon.mjs                # App icon generator
├── web/cartographer                     # Upstream submodule (Jannchie/cartographer)
└── StoryKit/
    ├── App/
    │   ├── StoryKitApp.swift            # SwiftUI App entry point
    │   └── AppCommands.swift            # Native AppKit menu commands (File, Help)
    ├── Bridge/
    │   ├── StoryKitSchemeHandler.swift  # WKURLSchemeHandler for storykit://app
    │   └── StoryKitBridge.swift         # WKScriptMessageHandler & native IPC bridge
    ├── Views/
    │   ├── ContentView.swift            # Main window view with drag & drop
    │   ├── StoryKitWebView.swift        # NSViewRepresentable wrapping WKWebView
    │   ├── SettingsView.swift           # Native Preferences panel
    │   └── WhatsNewSheetView.swift      # What's New release highlights sheet
    └── Resources/
        ├── Localizable.xcstrings        # Bilingual string catalog (en, zh-Hans)
        ├── Assets.xcassets              # Full-bleed 1024x1024 AppIcon
        └── web/                         # Bundled offline assets
```

## Getting Started

### Prerequisites

- macOS 14.0+ (Sonoma or Sequoia)
- Xcode 16.0+ (with Swift 6.0+)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- Node.js 20+ & [pnpm](https://pnpm.io/)

### Build & Run

1. **Clone the repository with submodules**:
   ```bash
   git clone --recurse-submodules https://github.com/SteveShi/StoryKit.git
   cd StoryKit
   ```

2. **Build web assets**:
   ```bash
   pnpm --dir web/cartographer install
   ./Scripts/sync-web.sh
   ```

3. **Generate Xcode Project**:
   ```bash
   xcodegen generate
   ```

4. **Build and Run**:
   Open `StoryKit.xcodeproj` in Xcode and press `⌘R`, or build via CLI:
   ```bash
   xcodebuild -scheme StoryKit -destination "platform=macOS" build
   ```

## License

- StoryKit macOS native wrapper is licensed under the [MIT License](LICENSE).
- Upstream Cartographer generator code is licensed under the [MIT License](web/cartographer/LICENSE) by Jannchie.
