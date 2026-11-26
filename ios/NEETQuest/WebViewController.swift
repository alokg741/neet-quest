import UIKit
import WebKit
import UserNotifications

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
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

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

        if let wwwDir = Bundle.main.url(forResource: "www", withExtension: nil) {
            let indexURL = wwwDir.appendingPathComponent("index.html")
            webView.loadFileURL(indexURL, allowingReadAccessTo: wwwDir)
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

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
        }
    }

    // Open external links (Google Drive, iCloud, Dropbox, etc.) in Safari
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
