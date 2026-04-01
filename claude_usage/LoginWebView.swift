import SwiftUI
import WebKit

struct LoginWebView: View {
    var viewModel: UsageViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(String(localized: "login.title"))
                    .font(.headline)
                Spacer()
                Button(String(localized: "login.cancel")) { dismiss() }
                    .buttonStyle(.borderless)
            }
            .padding(12)

            Divider()

            WebViewWrapper(onLoginSuccess: { cookies in
                viewModel.handleLoginSuccess(cookies: cookies)
                dismiss()
            })
        }
        .frame(width: 900, height: 700)
    }
}

struct WebViewWrapper: NSViewRepresentable {
    var onLoginSuccess: @MainActor ([HTTPCookie]) -> Void

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView
        context.coordinator.startURLObservation(webView)
        webView.load(URLRequest(url: URL(string: "https://claude.ai/login")!))
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onLoginSuccess: onLoginSuccess)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var onLoginSuccess: @MainActor ([HTTPCookie]) -> Void
        private var hasReported = false
        weak var webView: WKWebView?
        private var urlObservation: NSKeyValueObservation?

        init(onLoginSuccess: @MainActor @escaping ([HTTPCookie]) -> Void) {
            self.onLoginSuccess = onLoginSuccess
        }

        func startURLObservation(_ webView: WKWebView) {
            urlObservation = webView.observe(\.url, options: [.new]) { [weak self] wv, change in
                guard let self, let url = wv.url else { return }
                self.checkLoginSuccess(webView: wv, url: url)
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let url = webView.url else { return }
            checkLoginSuccess(webView: webView, url: url)
        }

        private func checkLoginSuccess(webView: WKWebView, url: URL) {
            guard !hasReported else { return }
            guard let host = url.host, host.contains("claude.ai") else { return }
            let path = url.path
            guard !path.contains("/login"), !path.contains("/oauth"), !path.contains("/auth/") else { return }

            hasReported = true

            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                let claudeCookies = cookies.filter { $0.domain.contains("claude.ai") }
                Task { @MainActor in
                    self.onLoginSuccess(claudeCookies)
                }
            }
        }

        deinit {
            urlObservation?.invalidate()
        }
    }
}
