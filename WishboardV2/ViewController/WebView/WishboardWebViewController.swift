//
//  WishboardWebViewController.swift
//  WishboardV2
//

import Foundation
import UIKit
import WebKit
import SnapKit
import Then
import Core
import WBNetwork
import EchoKit

final class WishboardWebViewController: UIViewController, Echoable {

    private static let webViewURL = "https://wishboard-app-web.vercel.app/"
    private static let bridgeName = "wishboard"

    /// 토큰이 주입되는 웹뷰라, 이 호스트 밖으로는 이동시키지 않습니다.
    private static let allowedHosts: Set<String> = {
        guard let host = URL(string: webViewURL)?.host?.lowercased() else { return [] }
        return [host]
    }()

    // MARK: - Views

    private let navigationBar = UIView().then {
        $0.backgroundColor = .white
    }

    private let closeButton = UIButton().then {
        $0.setImage(.x, for: .normal)
    }

    private var webView: WKWebView!

    // MARK: - Init

    override func loadView() {
        super.loadView()
        view.backgroundColor = .white
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = true

        Task {
            await setupWebView()
            setupUI()
            setupActions()
            loadWebView()
        }
    }

    // MARK: - Setup

    private func setupWebView() async {
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()

        // Bridge 등록
        userContentController.add(self, name: Self.bridgeName)

        // 초기 토큰/디바이스 정보 주입 스크립트 (atDocumentStart)
        if let script = await makeInitialInjectionScript() {
            // 하위 프레임(iframe)에는 주입하지 않습니다.
            // false 로 두면 페이지가 끼운 서드파티 iframe 에도 토큰이 그대로 들어갑니다.
            let userScript = WKUserScript(
                source: script,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
            userContentController.addUserScript(userScript)
        }

        config.userContentController = userContentController
        
        // MARK: WebView LOG
        // 주입 스크립트 본문에 토큰 원문이 들어 있어 디버그 빌드에서만 출력합니다.
        #if DEBUG
        let scripts = config.userContentController.userScripts
        let userScriptsLog = scripts.enumerated().map { index, script in
            """
            [Script \(index)]
            injectionTime: \(script.injectionTime)
            mainFrameOnly: \(script.isForMainFrameOnly)
            source:
            \(script.source)
            """
        }.joined(separator: "\n\n")

        print("""
        ===== 🌐 WebView UserScripts (\(scripts.count)) =====

        \(userScriptsLog)

        ================================================
        """)
        #endif

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self

        // User-Agent 커스텀 (기존 UA + Wishboard 환경 마커)
        webView.evaluateJavaScript("navigator.userAgent") { [weak self] result, _ in
            guard let self, let existingUA = result as? String else { return }
            #if DEBUG
            let marker = "wishboard-ios/dev"
            #else
            let marker = "wishboard-ios/prod"
            #endif
            self.webView.customUserAgent = "\(existingUA) \(marker)"
            
            print("""

                ===== 🌐 WebView User-Agent =====
                
                \(existingUA) \(marker)
                
                ===========================================

                """)
        }
    }

    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(navigationBar)
        view.addSubview(webView)

        navigationBar.addSubview(closeButton)

        navigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(42)
        }

        closeButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(13)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }

        webView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide)
        }
    }

    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }

    private func loadWebView() {
        guard let url = URL(string: Self.webViewURL) else { return }
        webView.load(URLRequest(url: url))
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    // MARK: - Token Injection

    private func makeInitialInjectionScript() async -> String? {
        guard let deviceInfo = UserManager.deviceInfo else { return nil }

        do {
            let tokenResponse = try await AuthManager.shared.requestWebViewToken()
            let token = tokenResponse.token ?? ""
            return """
            window.__WISHBOARD_TOKEN__ = '\(token)';
            window.__WISHBOARD_DEVICE_INFO__ = '\(deviceInfo)';
            """
        } catch {
            return """
            window.__WISHBOARD_TOKEN__ = '';
            window.__WISHBOARD_DEVICE_INFO__ = '\(deviceInfo)';
            """
        }
    }

    // MARK: - Bridge Response

    private func resolveWebBridge(requestId: Int, token: String, deviceInfo: String) {
        let js = """
        window.__WISHBOARD_BRIDGE__.resolve(\(requestId), {
            token: "\(token)",
            deviceInfo: "\(deviceInfo)"
        });
        """
        
        #if DEBUG
        print("""

            ===== 🌐 iOS → Web Bridge =====

            requestId: \(requestId)

            token: \(token.isEmpty ? "EMPTY" : "EXISTS")

            deviceInfo: \(deviceInfo)

            JS:

            \(js.replacingOccurrences(of: token, with: "[REDACTED]"))

            ==========================================

            """)
        #endif
        
        DispatchQueue.main.async { [weak self] in
            self?.webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    private func resolveWebBridgeWithError(requestId: Int, error: String) {
        let js = """
        window.__WISHBOARD_BRIDGE__.resolve(\(requestId), {
            error: "\(error)"
        });
        """
        
        #if DEBUG
        print("""

            ===== 🌐 iOS → Web Bridge =====

            requestId: \(requestId)

            error: \(error)

            JS:

            \(js)

            ==========================================

            """)
        #endif
        
        DispatchQueue.main.async { [weak self] in
            self?.webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
}

// MARK: - WKScriptMessageHandler

extension WishboardWebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        #if DEBUG
        print("""
        ======= 🌐 WebView → iOS Bridge =====
        name: \(message.name)
        body:
        \(message.body)
        =========================================
        """)
        #endif
        
        guard message.name == Self.bridgeName,
              let body = message.body as? [String: Any],
              let type = body["type"] as? String else { return }

        guard type == "REQUEST_WEBVIEW_TOKEN" else { return }

        let requestId = body["requestId"] as? Int ?? 0
        let reason = body["reason"] as? String ?? ""

        Task {
            do {
                let tokenResponse = try await AuthManager.shared.requestWebViewToken()
                guard let token = tokenResponse.token,
                      let deviceInfo = UserManager.deviceInfo else {
                    resolveWebBridgeWithError(requestId: requestId, error: "REAUTH_REQUIRED")
                    return
                }
                resolveWebBridge(requestId: requestId, token: token, deviceInfo: deviceInfo)
            } catch {
                resolveWebBridgeWithError(requestId: requestId, error: "REAUTH_REQUIRED")
            }
        }
    }
}

// MARK: - WKNavigationDelegate

extension WishboardWebViewController: WKNavigationDelegate {

    /// 허용한 호스트 밖으로는 이 웹뷰가 이동하지 않게 막습니다.
    ///
    /// 이 웹뷰에는 토큰을 주입하는 유저 스크립트가 걸려 있고, 그 스크립트는 한 번만 도는 것이 아니라
    /// **이 웹뷰에서 새로 뜨는 모든 문서**에 적용됩니다. 막아 두지 않으면 바깥 페이지로 한 번 이동하는 것만으로
    /// 그 페이지가 토큰을 읽을 수 있습니다. 외부 링크는 토큰이 없는 사파리로 넘깁니다.
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url,
              let scheme = url.scheme?.lowercased() else {
            decisionHandler(.cancel)
            return
        }

        // about:blank 등 웹뷰가 내부적으로 쓰는 전환은 그대로 둡니다.
        guard scheme != "about" else {
            decisionHandler(.allow)
            return
        }

        // tel:, mailto: 같은 것은 시스템에 넘깁니다.
        guard scheme == "http" || scheme == "https" else {
            decisionHandler(.cancel)
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
            return
        }

        if let host = url.host?.lowercased(), Self.allowedHosts.contains(host) {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
            UIApplication.shared.open(url)
        }
    }
}
