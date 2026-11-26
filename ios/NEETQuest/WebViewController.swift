import UIKit
import WebKit
import UserNotifications

class BundleSchemeHandler: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(NSError(domain: "NEETQuest", code: 404))
            return
        }
        var relPath = url.path
        if relPath.isEmpty || relPath == "/" { relPath = "/index.html" }
        if relPath.hasPrefix("/") { relPath.removeFirst() }

        let base = Bundle.main.url(forResource: "www", withExtension: nil)
            ?? Bundle.main.resourceURL?.appendingPathComponent("www")

        guard let fileURL = base?.appendingPathComponent(relPath),
              let data = try? Data(contentsOf: fileURL) else {
            urlSchemeTask.didFailWithError(NSError(domain: "NEETQuest", code: 404))
            return
        }

        let ext = fileURL.pathExtension.lowercased()
        let mime: String
        switch ext {
        case "html": mime = "text/html; charset=utf-8"
        case "js": mime = "application/javascript"
        case "css": mime = "text/css"
        case "json": mime = "application/json"
        case "jpg", "jpeg": mime = "image/jpeg"
        case "png": mime = "image/png"
        case "svg": mime = "image/svg+xml"
        default: mime = "application/octet-stream"
        }

        let resp = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": mime, "Access-Control-Allow-Origin": "*"]
        )!
        urlSchemeTask.didReceive(resp)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}
}

class WebViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {
    private var webView: WKWebView!
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let notifFeedback = UINotificationFeedbackGenerator()

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 6/255, green: 6/255, blue: 10/255, alpha: 1)

        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        notifFeedback.prepare()

        let contentController = WKUserContentController()
        contentController.add(self, name: "haptic")
        contentController.add(self, name: "notify")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.setURLSchemeHandler(BundleSchemeHandler(), forURLScheme: "nq")

        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 6/255, green: 6/255, blue: 10/255, alpha: 1)
        webView.scrollView.backgroundColor = UIColor(red: 6/255, green: 6/255, blue: 10/255, alpha: 1)
        webView.scrollView.bounces = true
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        webView.navigationDelegate = self
        webView.uiDelegate = self

        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        if let appURL = URL(string: "nq://app/index.html") {
            webView.load(URLRequest(url: appURL))
        }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "haptic", let kind = message.body as? String {
            DispatchQueue.main.async {
                switch kind {
                case "heavy":
                    self.notifFeedback.notificationOccurred(.success)
                    self.heavyImpact.impactOccurred()
                case "medium":
                    self.mediumImpact.impactOccurred()
                case "error":
                    self.notifFeedback.notificationOccurred(.error)
                default:
                    self.lightImpact.impactOccurred()
                }
            }
        } else if message.name == "notify", let dict = message.body as? [String: Any] {
            let title = dict["title"] as? String ?? "NEET Quest"
            let body = dict["body"] as? String ?? "Time to study!"
            let delay = max(1.0, (dict["delaySec"] as? Double) ?? 1.0)
            let isAlarm = (dict["isAlarm"] as? Bool) ?? false

            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                guard granted else { return }
                let offsets: [Double] = isAlarm ? [0, 15, 30] : [0]
                for offset in offsets {
                    let content = UNMutableNotificationContent()
                    content.title = title
                    content.body = body
                    content.sound = .default
                    if #available(iOS 15.0, *), isAlarm {
                        content.interruptionLevel = .timeSensitive
                    }
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay + offset, repeats: false)
                    let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                    center.add(req, withCompletionHandler: nil)
                }
            }
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let html = "<html><body style='background:#06060a;color:#fff;font-family:-apple-system;padding:40px;'><h2>NEET Quest</h2><p>Load error: \(error.localizedDescription)</p></body></html>"
        webView.loadHTMLString(html, baseURL: nil)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, navigationAction.navigationType == .linkActivated {
            if url.scheme == "http" || url.scheme == "https" {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            UIApplication.shared.open(url)
        }
        return nil
    }
}
