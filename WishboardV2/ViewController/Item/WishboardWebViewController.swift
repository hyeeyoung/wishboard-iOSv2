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

final class WishboardWebViewController: UIViewController {

    private static let webViewURL = "https://wishboard-app-web.vercel.app/"
    private static let bridgeName = "wishboard"

    // MARK: - Views

    private let navigationBar = UIView().then {
        $0.backgroundColor = .white
    }

    private let separatorLine = UIView().then {
        $0.backgroundColor = .gray_100
    }

    private let closeButton = UIButton().then {
        $0.setImage(Image.whiteQuit.withRenderingMode(.alwaysOriginal).withTintColor(.black), for: .normal)
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
            let userScript = WKUserScript(
                source: script,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            )
            userContentController.addUserScript(userScript)
        }

        config.userContentController = userContentController

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
        }
    }

    private func setupUI() {
        view.addSubview(navigationBar)
        view.addSubview(separatorLine)
        view.addSubview(webView)

        navigationBar.addSubview(closeButton)

        navigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(51)
        }

        closeButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }

        separatorLine.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }

        webView.snp.makeConstraints { make in
            make.top.equalTo(separatorLine.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
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
        DispatchQueue.main.async { [weak self] in
            self?.webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
}

// MARK: - WKScriptMessageHandler

extension WishboardWebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == Self.bridgeName,
              let body = message.body as? [String: Any],
              let type = body["type"] as? String else { return }

        guard type == "REQUEST_WEBVIEW_TOKEN" else { return }

        let requestId = body["requestId"] as? Int ?? 0
        let reason = body["reason"] as? String ?? ""
        print("[WebView Bridge] REQUEST_WEBVIEW_TOKEN received - requestId: \(requestId), reason: \(reason)")

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

extension WishboardWebViewController: WKNavigationDelegate { }
