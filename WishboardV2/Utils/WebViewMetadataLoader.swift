//
//  WebViewMetadataLoader.swift
//  WishboardV2
//
//  Created by gomin on 10/29/26.
//

import UIKit
import WebKit

/// 숨긴 웹뷰로 쇼핑몰 페이지를 실제로 렌더링한 뒤 og 태그를 읽어옵니다.
///
/// 서버 파싱도 LinkPresentation 도 막히는 사이트(쿠팡·자라·네이버 스마트스토어 등)를 위한
/// 마지막 수단입니다. 진짜 브라우저 엔진이라 봇 차단을 통과할 가능성이 가장 높은 대신,
/// 가장 무겁습니다. 공유 익스텐션은 메모리 한도가 낮으므로 `shareExtensionTimeout` 처럼
/// 더 짧은 시간을 줘서 빨리 정리되게 합니다.
///
/// User-Agent 는 WKWebView 기본값을 그대로 씁니다. 차단을 피하려고 다른 브라우저인 척
/// 꾸미지는 않습니다.
public final class WebViewMetadataLoader: NSObject {

    /// 페이지 로딩 + 값 추출까지 기다릴 최대 시간
    public static let defaultTimeout: TimeInterval = 15

    /// 공유 익스텐션용. 메모리 한도가 낮아 더 빨리 포기합니다.
    public static let shareExtensionTimeout: TimeInterval = 10

    /// 값이 비어 있을 때 다시 읽어 보는 횟수. JS 로 늦게 그려지는 페이지가 있습니다.
    private static let maxRetryCount = 3
    private static let retryInterval: TimeInterval = 1.0

    private var webView: WKWebView?
    private var continuation: CheckedContinuation<ParsedItemInfo, Never>?
    private var timeoutWorkItem: DispatchWorkItem?
    private var retryCount = 0
    /// 완료될 때까지 자기 자신을 살려 둡니다. (navigationDelegate 는 weak 입니다)
    private var selfRetain: WebViewMetadataLoader?

    /// - Parameter hostView: 웹뷰를 끼워 넣을 뷰. 화면에 붙어 있어야 WebKit 이 페이지를 제대로 그립니다.
    ///   공유 익스텐션에서는 `UIApplication.shared` 를 쓸 수 없어 호출하는 쪽에서 넘겨 줍니다.
    /// - Returns: 실패하더라도 에러를 던지지 않고 빈 값을 돌려줍니다.
    public static func load(from urlString: String,
                            in hostView: UIView?,
                            timeout: TimeInterval = defaultTimeout) async -> ParsedItemInfo {
        guard let url = URL(string: urlString),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return ParsedItemInfo()
        }

        let loader = WebViewMetadataLoader()
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                loader.start(url: url, hostView: hostView, timeout: timeout, continuation: continuation)
            }
        }
    }

    // MARK: - 로딩

    private func start(url: URL,
                       hostView: UIView?,
                       timeout: TimeInterval,
                       continuation: CheckedContinuation<ParsedItemInfo, Never>) {
        self.continuation = continuation
        self.selfRetain = self

        // 반응형 페이지가 모바일 레이아웃으로 그려지도록 화면 크기를 그대로 씁니다.
        let frame = hostView?.bounds ?? CGRect(x: 0, y: 0, width: 390, height: 844)

        let webView = WKWebView(frame: frame)
        webView.navigationDelegate = self
        webView.isUserInteractionEnabled = false
        // 완전히 투명하거나 숨김 상태면 렌더링을 건너뛰는 경우가 있어 아주 옅게만 둡니다.
        webView.alpha = 0.01
        // 맨 뒤에 깔아 둬서 화면에는 보이지 않습니다.
        hostView?.insertSubview(webView, at: 0)
        self.webView = webView

        let timeoutWorkItem = DispatchWorkItem { [weak self] in
            print("❌ 웹뷰 파싱 시간 초과: \(url.absoluteString)")
            self?.finish(with: ParsedItemInfo())
        }
        self.timeoutWorkItem = timeoutWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: timeoutWorkItem)

        webView.load(URLRequest(url: url))
    }

    private func finish(with result: ParsedItemInfo) {
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil

        webView?.stopLoading()
        webView?.navigationDelegate = nil
        webView?.removeFromSuperview()
        webView = nil

        continuation?.resume(returning: result)
        continuation = nil

        // 델리게이트 콜백 안에서 불릴 수 있어, 자기 참조 해제는 다음 런루프로 미룹니다.
        DispatchQueue.main.async { [self] in
            selfRetain = nil
        }
    }

    // MARK: - 값 추출

    private func extractMetadata() {
        guard let webView = webView else { return }

        webView.evaluateJavaScript(Self.extractionScript) { [weak self] result, error in
            guard let self = self, self.continuation != nil else { return }

            if let error = error {
                print("❌ 웹뷰 스크립트 실행 실패: \(error.localizedDescription)")
            }

            let parsed = Self.parse(result)
            if !parsed.isEmpty || self.retryCount >= Self.maxRetryCount {
                print("✅ 웹뷰 파싱 결과 - 이름: \(parsed.name ?? "없음") / 가격: \(parsed.price ?? "없음") / 이미지: \(parsed.imageUrl ?? "없음")")
                self.finish(with: parsed)
                return
            }

            // 아직 안 그려졌을 수 있어 조금 기다렸다 다시 읽습니다.
            self.retryCount += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.retryInterval) { [weak self] in
                self?.extractMetadata()
            }
        }
    }

    private static func parse(_ result: Any?) -> ParsedItemInfo {
        guard let json = result as? String,
              let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return ParsedItemInfo()
        }

        func text(_ key: String) -> String? {
            guard let value = (dict[key] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !value.isEmpty else { return nil }
            return value
        }

        // 가격은 "29,900원" 처럼 올 수 있어 숫자만 남깁니다.
        let price = text("price").map { String($0.filter { $0.isNumber }) }

        return ParsedItemInfo(name: text("title"),
                              price: (price?.isEmpty ?? true) ? nil : price,
                              imageUrl: text("image"))
    }

    /// og 태그를 먼저 보고, 없으면 JSON-LD 의 Product 정보를 읽습니다.
    private static let extractionScript = """
    (function() {
      function attr(selector) {
        var el = document.querySelector(selector);
        if (!el) return null;
        var value = el.getAttribute('content');
        return (value && value.trim()) ? value.trim() : null;
      }

      var title = attr('meta[property="og:title"]')
               || attr('meta[name="twitter:title"]');

      var image = attr('meta[property="og:image"]')
               || attr('meta[property="og:image:url"]')
               || attr('meta[name="twitter:image"]');

      var price = attr('meta[property="og:price:amount"]')
               || attr('meta[property="product:price:amount"]')
               || attr('meta[itemprop="price"]');

      if (!title || !image || !price) {
        var scripts = document.querySelectorAll('script[type="application/ld+json"]');
        for (var i = 0; i < scripts.length; i++) {
          try {
            var data = JSON.parse(scripts[i].textContent);
            var nodes = Array.isArray(data) ? data : [data];
            if (data['@graph']) nodes = nodes.concat(data['@graph']);

            for (var j = 0; j < nodes.length; j++) {
              var node = nodes[j];
              if (!node || node['@type'] !== 'Product') continue;

              if (!title && node.name) title = node.name;
              if (!image && node.image) {
                image = Array.isArray(node.image) ? node.image[0] : node.image;
              }
              var offers = node.offers;
              if (Array.isArray(offers)) offers = offers[0];
              if (!price && offers && offers.price) price = String(offers.price);
            }
          } catch (e) {}
        }
      }

      // og 태그가 하나도 없을 때의 마지막 수단. 사이트 이름이 들어올 수 있습니다.
      if (!title && document.title && document.title.trim()) {
        title = document.title.trim();
      }

      // 상대 주소로 온 이미지는 절대 주소로 바꿉니다.
      if (image) {
        try { image = new URL(image, location.href).href; } catch (e) {}
      }

      return JSON.stringify({ title: title, image: image, price: price });
    })()
    """
}

// MARK: - WKNavigationDelegate

extension WebViewMetadataLoader: WKNavigationDelegate {

    public func webView(_ webView: WKWebView,
                        decidePolicyFor navigationAction: WKNavigationAction,
                        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // navershopping:// 처럼 앱을 띄우려는 이동은 막고 현재 페이지를 그대로 둡니다.
        // 이걸 허용하면 페이지가 날아가서 og 태그를 못 읽습니다.
        guard let scheme = navigationAction.request.url?.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        extractMetadata()
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ 웹뷰 로딩 실패: \(error.localizedDescription)")
        // 일부만 그려졌어도 og 태그는 읽을 수 있어 한 번은 시도해 봅니다.
        extractMetadata()
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        // 위에서 막은 커스텀 스킴 이동이면 현재 페이지가 그대로 남아 있으니 그걸 읽습니다.
        // 102 는 WebKitErrorFrameLoadInterruptedByPolicyChange 입니다.
        if nsError.code == NSURLErrorCancelled || nsError.code == 102 {
            extractMetadata()
            return
        }

        print("❌ 웹뷰 접속 실패: \(error.localizedDescription)")
        finish(with: ParsedItemInfo())
    }
}
