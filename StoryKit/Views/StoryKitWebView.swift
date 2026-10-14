import SwiftUI
import WebKit

public struct StoryKitWebView: NSViewRepresentable {
    @ObservedObject public var bridge: StoryKitBridge

    public init(bridge: StoryKitBridge) {
        self.bridge = bridge
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let schemeHandler = StoryKitSchemeHandler()
        config.setURLSchemeHandler(schemeHandler, forURLScheme: "storykit")

        let contentController = WKUserContentController()
        contentController.addUserScript(StoryKitBridge.userScript)
        contentController.add(bridge, name: "storyKit")
        config.userContentController = contentController

        #if DEBUG
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        #endif

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground") // Transparent background while loading

        bridge.webView = webView

        if let initialURL = URL(string: "storykit://app/index.html") {
            webView.load(URLRequest(url: initialURL))
        }

        return webView
    }

    public func updateNSView(_ nsView: WKWebView, context: Context) {
        // State updates if necessary
    }

    public final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: StoryKitWebView

        init(_ parent: StoryKitWebView) {
            self.parent = parent
        }

        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.bridge.syncPreferences()
        }

        public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
            print("[StoryKit] Navigation failed:", error.localizedDescription)
        }
    }
}
