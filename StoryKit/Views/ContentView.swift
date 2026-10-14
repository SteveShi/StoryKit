import SwiftUI
import UniformTypeIdentifiers

public struct ContentView: View {
    @ObservedObject public var bridge: StoryKitBridge
    @State private var isTargeted = false

    public init(bridge: StoryKitBridge) {
        self.bridge = bridge
    }

    public var body: some View {
        StoryKitWebView(bridge: bridge)
            .ignoresSafeArea()
            .onOpenURL { url in
                bridge.openProjectFile(at: url)
            }
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                guard let provider = providers.first else { return false }
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url {
                        Task { @MainActor in
                            bridge.openProjectFile(at: url)
                        }
                    }
                }
                return true
            }
    }
}
