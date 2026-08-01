// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

// Gerege SSO нэвтрэлт — вэбтэй ЯГ ИЖИЛ урсгал, бүхэлдээ платформын BFF-ээр:
//
//   /api/auth/sso/start → Gerege SSO (нэвтрэлт) → /sso/callback (cookie суулгана)
//   → /me/dashboard
//
// Апп нь SSO дээр ӨӨРИЙН OIDC client бүртгүүлэхгүй (native/PKCE урсгал байхгүй) —
// вэб client-ийн логикийг тэр чигт нь ашиглана. Ингэснээр нэвтрэлтийн бодлого
// нэг л газар (BFF) байрлана.
//
// Дашбоард руу шилжих АГШИНД навигацыг зогсоож, WKWebView-ийн cookie-г
// `HTTPCookieStorage.shared` руу хуулна: цаашид APIClient тэр session-оор
// ажиллана. Вэб дашбоардыг апп дотор РЕНДЭРЛЭХГҮЙ — native дэлгэц рүү шилжинэ.
//
// Энэ нь `mobile/ios/TemplateApp/Sources/SSOWebView.swift`-ийн macOS хувилбар:
// UIViewRepresentable → NSViewRepresentable, бусад логик ижил.

import SwiftUI
import WebKit

struct SSOWebView: NSViewRepresentable {
    let onDone: () -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onDone: onDone, onCancel: onCancel)
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // Нэвтрэлтийн cookie нь тогтвортой сан руу суух ёстой — эс бөгөөс апп
        // хаагдахад session алдагдана.
        config.websiteDataStore = .default()
        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = context.coordinator
        web.load(URLRequest(url: APIClient.baseURL.appendingPathComponent("/api/auth/sso/start")))
        return web
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let onDone: () -> Void
        private let onCancel: () -> Void
        private var finished = false

        init(onDone: @escaping () -> Void, onCancel: @escaping () -> Void) {
            self.onDone = onDone
            self.onCancel = onCancel
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            // Cookie суусны дараа BFF нь /me/... руу шилжүүлнэ — яг энд зогсооно.
            if url.host == APIClient.baseURL.host, url.path.hasPrefix("/me"), !finished {
                finished = true
                decisionHandler(.cancel)
                Task { @MainActor in
                    await Self.syncCookies(from: webView)
                    onDone()
                }
                return
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            guard !finished else { return }
            finished = true
            Task { @MainActor in onCancel() }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            guard !finished else { return }
            // Навигацыг өөрсдөө цуцалсан үед (NSURLErrorCancelled) алдаа гэж үзэхгүй.
            if (error as NSError).code == NSURLErrorCancelled { return }
            finished = true
            Task { @MainActor in onCancel() }
        }

        /// WKWebView-ийн cookie сан → HTTPCookieStorage.shared (URLSession уншина).
        @MainActor
        private static func syncCookies(from webView: WKWebView) async {
            let store = webView.configuration.websiteDataStore.httpCookieStore
            let cookies: [HTTPCookie] = await withCheckedContinuation { cont in
                store.getAllCookies { cont.resume(returning: $0) }
            }
            for cookie in cookies { HTTPCookieStorage.shared.setCookie(cookie) }
        }
    }
}
