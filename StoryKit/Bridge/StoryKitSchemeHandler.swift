import Foundation
import WebKit
import UniformTypeIdentifiers

/// Custom scheme handler serving local bundled web assets under `storykit://app/`
public final class StoryKitSchemeHandler: NSObject, WKURLSchemeHandler, @unchecked Sendable {
    private let lock = NSLock()
    private var stoppedTasks = Set<ObjectIdentifier>()

    public override init() {
        super.init()
    }

    public func webView(_ webView: WKWebView, start urlSchemeTask: any WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            fail(urlSchemeTask, statusCode: 400, message: "Invalid URL")
            return
        }

        var relativePath = url.path
        if relativePath.isEmpty || relativePath == "/" {
            relativePath = "/index.html"
        }
        if relativePath.hasPrefix("/") {
            relativePath.removeFirst()
        }

        // 1. Resolve local file URL
        guard let fileURL = resolveAssetURL(for: relativePath) else {
            fail(urlSchemeTask, statusCode: 404, message: "File not found: \(relativePath)")
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let mimeType = mimeType(for: fileURL.pathExtension)
            
            var headers: [String: String] = [
                "Content-Type": mimeType,
                "Content-Length": String(data.count),
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
                "Access-Control-Allow-Headers": "*",
                "Cache-Control": "no-cache"
            ]

            guard let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: headers
            ) else {
                fail(urlSchemeTask, statusCode: 500, message: "Internal Response Creation Error")
                return
            }

            lock.lock()
            let isStopped = stoppedTasks.contains(ObjectIdentifier(urlSchemeTask))
            lock.unlock()

            guard !isStopped else { return }

            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(data)
            urlSchemeTask.didFinish()
        } catch {
            fail(urlSchemeTask, statusCode: 500, message: error.localizedDescription)
        }
    }

    public func webView(_ webView: WKWebView, stop urlSchemeTask: any WKURLSchemeTask) {
        lock.lock()
        stoppedTasks.insert(ObjectIdentifier(urlSchemeTask))
        lock.unlock()
    }

    private func fail(_ task: any WKURLSchemeTask, statusCode: Int, message: String) {
        lock.lock()
        let isStopped = stoppedTasks.contains(ObjectIdentifier(task))
        lock.unlock()
        guard !isStopped else { return }

        let data = message.data(using: .utf8) ?? Data()
        if let response = HTTPURLResponse(
            url: task.request.url ?? URL(string: "storykit://app/")!,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: [
                "Content-Type": "text/plain; charset=utf-8",
                "Content-Length": String(data.count)
            ]
        ) {
            task.didReceive(response)
            task.didReceive(data)
            task.didFinish()
        }
    }

    private func resolveAssetURL(for relativePath: String) -> URL? {
        // Priority 1: Main bundle resource folder "web"
        if let bundleWebURL = Bundle.main.url(forResource: "web", withExtension: nil) {
            let targetURL = bundleWebURL.appendingPathComponent(relativePath)
            if FileManager.default.fileExists(atPath: targetURL.path) {
                return targetURL
            }
        }

        // Priority 2: Direct lookup in Bundle.main.resourceURL
        if let resourceURL = Bundle.main.resourceURL {
            let targetURL = resourceURL.appendingPathComponent("web").appendingPathComponent(relativePath)
            if FileManager.default.fileExists(atPath: targetURL.path) {
                return targetURL
            }
        }

        // Priority 3: Fallback during local Xcode debugging
        let localCandidate = URL(fileURLWithPath: "StoryKit/Resources/web").appendingPathComponent(relativePath)
        if FileManager.default.fileExists(atPath: localCandidate.path) {
            return localCandidate
        }

        return nil
    }

    private func mimeType(for pathExtension: String) -> String {
        switch pathExtension.lowercased() {
        case "html", "htm":
            return "text/html; charset=utf-8"
        case "js", "mjs":
            return "application/javascript; charset=utf-8"
        case "css":
            return "text/css; charset=utf-8"
        case "svg":
            return "image/svg+xml"
        case "png":
            return "image/png"
        case "jpg", "jpeg":
            return "image/jpeg"
        case "webp":
            return "image/webp"
        case "ico":
            return "image/x-icon"
        case "json":
            return "application/json"
        case "wasm":
            return "application/wasm"
        case "bin", "dat":
            return "application/octet-stream"
        case "ttf":
            return "font/ttf"
        case "woff":
            return "font/woff"
        case "woff2":
            return "font/woff2"
        default:
            if let utType = UTType(filenameExtension: pathExtension),
               let preferredMIME = utType.preferredMIMEType {
                return preferredMIME
            }
            return "application/octet-stream"
        }
    }
}
