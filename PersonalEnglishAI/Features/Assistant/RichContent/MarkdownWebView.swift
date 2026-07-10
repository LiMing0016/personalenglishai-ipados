import SwiftUI
@preconcurrency import WebKit

struct MarkdownWebView: UIViewRepresentable {
    let blocks: [RichContentBlock]
    @Binding var contentHeight: CGFloat
    var onEvent: (RichContentWebEvent) -> Void = { _ in }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.userContentController.add(context.coordinator, name: "richContent")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear

        if let rendererURL = Self.rendererURL {
            webView.loadFileURL(rendererURL, allowingReadAccessTo: rendererURL.deletingLastPathComponent())
        } else {
            assertionFailure("RichRenderer/renderer.html is missing from the app bundle.")
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.pendingBlocks = blocks
        context.coordinator.renderIfReady(in: webView)
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "richContent")
    }

    private static var rendererURL: URL? {
        let candidates = [
            "RichRenderer",
            "Resources/RichRenderer",
            "PersonalEnglishAI/Resources/RichRenderer"
        ]
        for subdirectory in candidates {
            if let url = Bundle.main.url(forResource: "renderer", withExtension: "html", subdirectory: subdirectory) {
                return url
            }
        }
        return Bundle.main.url(forResource: "renderer", withExtension: "html")
    }

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        var parent: MarkdownWebView
        var pendingBlocks: [RichContentBlock] = []
        private var didFinishLoading = false
        private var lastPayload = ""

        init(parent: MarkdownWebView) {
            self.parent = parent
            self.pendingBlocks = parent.blocks
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            didFinishLoading = true
            renderIfReady(in: webView)
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let payload = message.body as? [String: Any],
                  let type = payload["type"] as? String else {
                return
            }

            switch type {
            case "heightChanged":
                guard let height = numericValue(payload["height"]) else {
                    return
                }
                parent.contentHeight = max(1, height)
                parent.onEvent(.heightChanged(height))
            case "linkTapped":
                if let value = payload["url"] as? String,
                   let url = URL(string: value),
                   url.scheme?.lowercased().hasPrefix("javascript") != true {
                    parent.onEvent(.linkTapped(url))
                }
            case "copyRequested":
                if let text = payload["text"] as? String {
                    parent.onEvent(.copyRequested(text))
                }
            case "graphFullscreenRequested":
                if let id = payload["id"] as? String {
                    parent.onEvent(.graphFullscreenRequested(id))
                }
            case "renderError":
                if let message = payload["message"] as? String {
                    parent.onEvent(.renderError(message))
                }
            default:
                return
            }
        }

        private func numericValue(_ value: Any?) -> CGFloat? {
            if let value = value as? CGFloat {
                return value
            }
            if let value = value as? Double {
                return CGFloat(value)
            }
            if let value = value as? NSNumber {
                return CGFloat(truncating: value)
            }
            return nil
        }

        func renderIfReady(in webView: WKWebView) {
            guard didFinishLoading,
                  let payload = makePayload(blocks: pendingBlocks),
                  payload != lastPayload else {
                return
            }
            lastPayload = payload
            let script = "window.renderRichContent(\(payload));"
            webView.evaluateJavaScript(script)
        }

        private func makePayload(blocks: [RichContentBlock]) -> String? {
            let payload = RichContentPayload(theme: "light", blocks: blocks)
            let encoder = JSONEncoder()
            guard let data = try? encoder.encode(payload) else {
                return nil
            }
            return String(data: data, encoding: .utf8)
        }
    }
}

private struct RichContentPayload: Encodable {
    let theme: String
    let blocks: [RichContentBlock]
}

extension MarkdownWebView.Coordinator {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard navigationAction.navigationType == .linkActivated else {
            decisionHandler(.allow)
            return
        }
        if let url = navigationAction.request.url {
            parent.onEvent(.linkTapped(url))
        }
        decisionHandler(.cancel)
    }
}
