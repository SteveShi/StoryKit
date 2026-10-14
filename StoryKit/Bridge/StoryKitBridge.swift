import Foundation
import WebKit
import AppKit
import UniformTypeIdentifiers

@MainActor
public final class StoryKitBridge: NSObject, WKScriptMessageHandler, ObservableObject {
    public weak var webView: WKWebView?
    
    public override init() {
        super.init()
    }

    // MARK: - Injected JavaScript Glue
    public static var userScript: WKUserScript {
        let scriptSource = """
        (function() {
            if (window.__STORYKIT_INITIALIZED__) return;
            window.__STORYKIT_INITIALIZED__ = true;

            window.StoryKitNative = {
                isMacNative: true,
                version: "1.0.0",

                saveFile: function(filename, blobOrDataUrl) {
                    if (typeof blobOrDataUrl === 'string') {
                        window.webkit.messageHandlers.storyKit.postMessage({
                            action: "saveFile",
                            filename: filename,
                            data: blobOrDataUrl
                        });
                    } else if (blobOrDataUrl instanceof Blob) {
                        const reader = new FileReader();
                        reader.onload = function() {
                            window.webkit.messageHandlers.storyKit.postMessage({
                                action: "saveFile",
                                filename: filename,
                                data: reader.result
                            });
                        };
                        reader.readAsDataURL(blobOrDataUrl);
                    }
                },

                openProjectJson: function(jsonString) {
                    try {
                        const parsed = JSON.parse(jsonString);
                        const blob = new Blob([jsonString], { type: 'application/json' });
                        const file = new File([blob], 'project.json', { type: 'application/json' });
                        
                        // Look for the hidden file input used in App.vue or trigger openProject directly
                        const fileInputs = document.querySelectorAll('input[type="file"]');
                        if (fileInputs.length > 0) {
                            const input = fileInputs[0];
                            const dt = new DataTransfer();
                            dt.items.add(file);
                            input.files = dt.files;
                            input.dispatchEvent(new Event('change', { bubbles: true }));
                        } else {
                            window.dispatchEvent(new CustomEvent('storykit:open-project', { detail: { json: jsonString, doc: parsed } }));
                        }
                    } catch (e) {
                        console.error("[StoryKit] Failed to parse project JSON:", e);
                    }
                },

                triggerNewWorld: function() {
                    // Trigger a random seed generation in World Panel
                    const seedInputs = document.querySelectorAll('input[placeholder*="种子"], input[placeholder*="seed"]');
                    if (seedInputs.length > 0) {
                        const input = seedInputs[0];
                        input.value = Math.random().toString(36).substring(2, 9);
                        input.dispatchEvent(new Event('input', { bubbles: true }));
                        input.dispatchEvent(new Event('change', { bubbles: true }));
                    } else {
                        // Reload or dispatch event
                        window.location.reload();
                    }
                },

                triggerExportProject: function() {
                    // Find and click the world file export button
                    const buttons = Array.from(document.querySelectorAll('button, [role="button"]'));
                    const targetBtn = buttons.find(b => b.textContent && (b.textContent.includes('世界文件') || b.textContent.includes('World file') || b.title?.includes('世界文件')));
                    if (targetBtn) {
                        targetBtn.click();
                    } else {
                        // Try open export menu first if present
                        const exportTriggers = buttons.filter(b => b.title?.includes('导出') || b.textContent?.includes('导出') || b.title?.includes('Export'));
                        if (exportTriggers.length > 0) {
                            exportTriggers[0].click();
                            setTimeout(() => {
                                const subButtons = Array.from(document.querySelectorAll('button, [role="button"]'));
                                const subTarget = subButtons.find(b => b.textContent && (b.textContent.includes('世界文件') || b.textContent.includes('World file')));
                                if (subTarget) subTarget.click();
                            }, 150);
                        }
                    }
                },

                triggerExportMap: function(format) {
                    const fmt = (format || 'png').toUpperCase();
                    const buttons = Array.from(document.querySelectorAll('button, [role="button"]'));
                    const targetBtn = buttons.find(b => b.textContent && b.textContent.trim().toUpperCase() === fmt);
                    if (targetBtn) {
                        targetBtn.click();
                    } else {
                        const exportTriggers = buttons.filter(b => b.title?.includes('导出') || b.textContent?.includes('导出') || b.title?.includes('Export'));
                        if (exportTriggers.length > 0) {
                            exportTriggers[0].click();
                            setTimeout(() => {
                                const subButtons = Array.from(document.querySelectorAll('button, [role="button"]'));
                                const subTarget = subButtons.find(b => b.textContent && b.textContent.trim().toUpperCase() === fmt);
                                if (subTarget) subTarget.click();
                            }, 150);
                        }
                    }
                },

                syncPreferences: function(prefs) {
                    if (!prefs) return;
                    for (const [key, val] of Object.entries(prefs)) {
                        try {
                            localStorage.setItem(key, String(val));
                        } catch (e) {}
                    }
                }
            };

            // Intercept automatic anchor tag downloads
            const originalCreateElement = document.createElement.bind(document);
            document.createElement = function(tagName, options) {
                const element = originalCreateElement(tagName, options);
                if (tagName && tagName.toLowerCase() === 'a') {
                    const originalClick = element.click.bind(element);
                    element.click = function() {
                        if (element.hasAttribute('download')) {
                            const filename = element.getAttribute('download') || 'download';
                            const href = element.getAttribute('href');
                            if (href) {
                                if (href.startsWith('data:') || href.startsWith('blob:')) {
                                    fetch(href)
                                        .then(res => res.blob())
                                        .then(blob => {
                                            window.StoryKitNative.saveFile(filename, blob);
                                        })
                                        .catch(() => originalClick());
                                    return;
                                }
                            }
                        }
                        originalClick();
                    };
                }
                return element;
            };
        })();
        """

        return WKUserScript(
            source: scriptSource,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
    }

    // MARK: - WKScriptMessageHandler
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "storyKit",
              let body = message.body as? [String: Any],
              let action = body["action"] as? String else {
            return
        }

        switch action {
        case "saveFile":
            handleSaveFile(payload: body)
        case "openFileDialog":
            handleOpenFileDialog()
        default:
            break
        }
    }

    // MARK: - Save Dialog
    private func handleSaveFile(payload: [String: Any]) {
        guard let filename = payload["filename"] as? String,
              let dataString = payload["data"] as? String else {
            return
        }

        var rawData: Data?
        if dataString.starts(with: "data:") {
            if let commaIndex = dataString.firstIndex(of: ",") {
                let base64Part = String(dataString[dataString.index(after: commaIndex)...])
                rawData = Data(base64Encoded: base64Part, options: .ignoreUnknownCharacters)
            }
        } else {
            rawData = dataString.data(using: .utf8)
        }

        guard let fileData = rawData else { return }

        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = filename
        savePanel.isExtensionHidden = false

        let ext = (filename as NSString).pathExtension
        if !ext.isEmpty, let utType = UTType(filenameExtension: ext) {
            savePanel.allowedContentTypes = [utType]
        }

        // Default export directory if set in user defaults
        if let defaultDir = UserDefaults.standard.string(forKey: "defaultExportDirectory"),
           !defaultDir.isEmpty {
            savePanel.directoryURL = URL(fileURLWithPath: defaultDir)
        }

        guard let window = NSApp.keyWindow ?? NSApp.windows.first else { return }

        savePanel.beginSheetModal(for: window) { response in
            if response == .OK, let targetURL = savePanel.url {
                do {
                    try fileData.write(to: targetURL, options: .atomic)
                } catch {
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("storykit.alert.save_error.title", comment: "Save Error")
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .warning
                    alert.runModal()
                }
            }
        }
    }

    // MARK: - Open Dialog
    public func handleOpenFileDialog() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = [
            UTType(filenameExtension: "storykit") ?? .json,
            UTType(filenameExtension: "carto") ?? .json,
            .json
        ]

        guard let window = NSApp.keyWindow ?? NSApp.windows.first else { return }

        openPanel.beginSheetModal(for: window) { [weak self] response in
            if response == .OK, let selectedURL = openPanel.url {
                self?.openProjectFile(at: selectedURL)
            }
        }
    }

    public func openProjectFile(at fileURL: URL) {
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let escaped = content
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "`", with: "\\`")
                .replacingOccurrences(of: "$", with: "\\$")

            let js = "window.StoryKitNative?.openProjectJson(`\(escaped)`);"
            webView?.evaluateJavaScript(js, completionHandler: nil)
        } catch {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("storykit.alert.open_error.title", comment: "Open Error")
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.runModal()
        }
    }

    // MARK: - Native Commands
    public func triggerNewWorld() {
        webView?.evaluateJavaScript("window.StoryKitNative?.triggerNewWorld();", completionHandler: nil)
    }

    public func triggerExportProject() {
        webView?.evaluateJavaScript("window.StoryKitNative?.triggerExportProject();", completionHandler: nil)
    }

    public func triggerExportMap(format: String) {
        webView?.evaluateJavaScript("window.StoryKitNative?.triggerExportMap('\(format)');", completionHandler: nil)
    }

    public func syncPreferences() {
        let atlasStyle = UserDefaults.standard.string(forKey: "atlasStyle") ?? "physical"
        let quality = UserDefaults.standard.string(forKey: "quality") ?? "high"
        let dayCycle = UserDefaults.standard.bool(forKey: "dayCycle") ? "1" : "0"
        let locale = UserDefaults.standard.string(forKey: "locale") ?? "zh-CN"

        let prefsDict: [String: String] = [
            "atlasStyle": atlasStyle,
            "quality": quality,
            "dayCycle": dayCycle,
            "locale": locale
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: prefsDict, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            let js = "window.StoryKitNative?.syncPreferences(\(jsonString));"
            webView?.evaluateJavaScript(js, completionHandler: nil)
        }
    }
}
