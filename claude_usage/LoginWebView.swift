import SwiftUI
import WebKit
import AppKit

struct LoginWebView: View {
    var viewModel: UsageViewModel
    var closeWindow: () -> Void
    @State private var loginSucceeded = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Text(String(localized: "login.title"))
                        .font(.headline)
                    Spacer()
                    Button(String(localized: "login.cancel")) {
                        closeWindow()
                    }
                    .buttonStyle(.borderless)
                }
                .padding(12)

                Divider()

                WebViewWrapper(
                    onLoginSuccess: { cookies in
                        viewModel.handleLoginSuccess(cookies: cookies)
                        withAnimation(.easeInOut(duration: 0.3)) {
                            loginSucceeded = true
                        }
                    }
                )
            }

            if loginSucceeded {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.green)
                    Text(String(localized: "login.success"))
                        .font(.title.weight(.semibold))
                    VStack(spacing: 6) {
                        Text(String(localized: "login.success.hint"))
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Image(systemName: "arrow.up")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    Button(String(localized: "login.done")) {
                        closeWindow()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.regularMaterial)
                .transition(.opacity)
            }
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
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.3 Safari/605.1.15"
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        context.coordinator.webView = webView
        context.coordinator.startURLObservation(webView)
        webView.load(URLRequest(url: URL(string: "https://claude.ai/login")!))
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onLoginSuccess: onLoginSuccess)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var onLoginSuccess: @MainActor ([HTTPCookie]) -> Void
        private var hasReported = false
        weak var webView: WKWebView?
        private var urlObservation: NSKeyValueObservation?
        private var pollTimer: Timer?

        init(onLoginSuccess: @MainActor @escaping ([HTTPCookie]) -> Void) {
            self.onLoginSuccess = onLoginSuccess
        }

        func startURLObservation(_ webView: WKWebView) {
            urlObservation = webView.observe(\.url, options: [.new]) { [weak self] wv, _ in
                guard let self, let url = wv.url else { return }
                self.checkLoginSuccess(webView: wv, url: url)
            }
        }

        // MARK: - WKNavigationDelegate

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let url = webView.url else { return }
            checkLoginSuccess(webView: webView, url: url)
        }

        // MARK: - WKUIDelegate (OAuth popup handling)

        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
            return nil
        }

        // MARK: - Detection

        private func checkLoginSuccess(webView: WKWebView, url: URL) {
            guard !hasReported else { return }
            guard let host = url.host, host.contains("claude.ai") else { return }

            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
                guard let self else { return }
                let claudeCookies = cookies.filter { $0.domain.contains("claude.ai") }
                let hasSession = claudeCookies.contains { cookie in
                    let name = cookie.name.lowercased()
                    return name.contains("sessionkey") || name.contains("session_key")
                }
                guard hasSession else {
                    self.schedulePoll(webView: webView)
                    return
                }
                self.hasReported = true
                self.stopPoll()
                Task { @MainActor in
                    self.onLoginSuccess(claudeCookies)
                }
            }
        }

        private func schedulePoll(webView: WKWebView) {
            guard pollTimer == nil else { return }
            let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self, weak webView] _ in
                guard let self, let wv = webView, let url = wv.url else { return }
                self.checkLoginSuccess(webView: wv, url: url)
            }
            RunLoop.main.add(timer, forMode: .common)
            pollTimer = timer
        }

        private func stopPoll() {
            pollTimer?.invalidate()
            pollTimer = nil
        }

        deinit {
            urlObservation?.invalidate()
            pollTimer?.invalidate()
        }
    }
}
