# StoryKit

[English](README.md) · 简体中文

**StoryKit** 是一款基于 Swift 6 与 SwiftUI 打造的 macOS 原生虚构世界与地图生成套件，内核由开源项目 [Jannchie/cartographer](https://github.com/Jannchie/cartographer) 驱动。

<p align="center">
  <img src="docs/images/world-3d-zh.webp" alt="StoryKit 3D 沙盘视图" width="90%">
</p>

## 特性亮点

- **macOS 纯原生质感**：基于 Swift 6.0 与 SwiftUI 构建，完美集成系统级菜单栏快捷键（`⌘N` 新建、`⌘O` 打开、`⌘S` 保存、`⌘E` 导出）、`NSSavePanel` / `NSOpenPanel` 文件存取对话框以及系统深色模式。
- **100% 离线与私密安全**：内置 `storykit://app/` 自定义安全协议，无需依赖外网服务器，彻底避免浏览器跨域策略与系统防火墙弹窗。
- **专业级过程式地理生成**：
  - **地壳板块与水力侵蚀**：模拟板块碰撞抬升、河流下切侵蚀、地形阻挡降水与优先流汇水模型，发育自然地貌。
  - **四大历史文化聚落文法**：支持西方、中式、日式与伊斯兰四大文化聚落体系，城镇规模无级伸缩，依山傍水生成街道与地标。
  - **丰富多样的地图制图风格**：涵盖物理地图、奇幻卷轴、古典海图、提瓦特、水墨淡彩与等高线测绘图，兼具体积云光影 3D 立体画与全息投影台视口。
- **零侵入的上游同步工作流**：前端核心通过 Git Submodule 管理，未来拉取上游算法更新只需一条命令，外壳代码无需变动。
- **严谨的工程标准**：全量接入 `Localizable.xcstrings`（中英双语、零硬编码文本）、所有原生设置项均直连底层配置，遵循 Apple HIG 设计规范。

## 架构概览

```
StoryKit/
├── project.yml                          # XcodeGen 项目定义文件
├── Scripts/
│   ├── sync-web.sh                      # 前端生产打包与资源同步脚本
│   └── generate-icon.mjs                # macOS 原生平铺全出血图标生成脚本
├── web/cartographer                     # 上游 Git Submodule (Jannchie/cartographer)
└── StoryKit/
    ├── App/
    │   ├── StoryKitApp.swift            # SwiftUI 应用主入口
    │   └── AppCommands.swift            # AppKit 原生菜单栏指令（File、Help）
    ├── Bridge/
    │   ├── StoryKitSchemeHandler.swift  # 离线安全协议 storykit://app 处理器
    │   └── StoryKitBridge.swift         # WKScriptMessageHandler 原生双向 IPC 桥接
    ├── Views/
    │   ├── ContentView.swift            # 主窗口视图（支持拖拽文件导入）
    │   ├── StoryKitWebView.swift        # 封装 WKWebView 的 NSViewRepresentable
    │   ├── SettingsView.swift           # 原生偏好设置面板（画质/风格/导出）
    │   └── WhatsNewSheetView.swift      # What's New 新特性介绍弹窗（挂载于 Help 菜单）
    └── Resources/
        ├── Localizable.xcstrings        # 双语本地化字符目录（中/英）
        ├── Assets.xcassets              # 1024x1024 全出血 AppIcon
        └── web/                         # 离线打包内置资源
```

## 快速上手

### 环境要求

- macOS 14.0+ (Sonoma 或 Sequoia)
- Xcode 16.0+（支持 Swift 6.0+）
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- Node.js 20+ 以及 [pnpm](https://pnpm.io/)

### 编译与运行

1. **克隆项目及子模块**：
   ```bash
   git clone --recurse-submodules https://github.com/SteveShi/StoryKit.git
   cd StoryKit
   ```

2. **编译前端静态资源**：
   ```bash
   pnpm --dir web/cartographer install
   ./Scripts/sync-web.sh
   ```

3. **生成 Xcode 工程**：
   ```bash
   xcodegen generate
   ```

4. **构建运行**：
   在 Xcode 中打开 `StoryKit.xcodeproj` 并按 `⌘R` 运行，或在终端构建：
   ```bash
   xcodebuild -scheme StoryKit -destination "platform=macOS" build
   ```

## 开源协议

- StoryKit 原生外壳遵循 [MIT License](LICENSE)。
- 上游 Cartographer 生成器算法由 Jannchie 编写，遵循 [MIT License](web/cartographer/LICENSE)。
