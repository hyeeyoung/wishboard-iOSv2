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
    private static let maxRetryCount = 4
    private static let retryInterval: TimeInterval = 1.0

    private var webView: WKWebView?
    private var continuation: CheckedContinuation<ParsedItemInfo, Never>?
    private var timeoutWorkItem: DispatchWorkItem?
    private var memoryPressureSource: DispatchSourceMemoryPressure?
    private var retryCount = 0
    /// 중간 페이지를 건너뛰려고 우리가 직접 취소한 이동인지
    private var isSkippingBridgePage = false
    /// 완료될 때까지 자기 자신을 살려 둡니다. (navigationDelegate 는 weak 입니다)
    private var selfRetain: WebViewMetadataLoader?

    /// - Parameter hostView: 웹뷰를 끼워 넣을 뷰. 화면에 붙어 있어야 WebKit 이 페이지를 제대로 그립니다.
    ///   공유 익스텐션에서는 `UIApplication.shared` 를 쓸 수 없어 호출하는 쪽에서 넘겨 줍니다.
    /// - Returns: 실패하더라도 에러를 던지지 않고 빈 값을 돌려줍니다.
    /// - Parameter blocksHeavyResources: 이미지·동영상·폰트를 안 받아 메모리를 아낄지 여부.
    ///   메모리는 줄지만 그것들을 기다렸다 동작하는 페이지에서는 값을 못 읽을 수 있어 기본은 끔입니다.
    public static func load(from urlString: String,
                            in hostView: UIView?,
                            timeout: TimeInterval = defaultTimeout,
                            blocksHeavyResources: Bool = false) async -> ParsedItemInfo {
        guard let url = URL(string: urlString),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return ParsedItemInfo()
        }

        let loader = WebViewMetadataLoader()
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                loader.start(url: url,
                             hostView: hostView,
                             timeout: timeout,
                             blocksHeavyResources: blocksHeavyResources,
                             continuation: continuation)
            }
        }
    }

    // MARK: - 로딩

    private func start(url: URL,
                       hostView: UIView?,
                       timeout: TimeInterval,
                       blocksHeavyResources: Bool,
                       continuation: CheckedContinuation<ParsedItemInfo, Never>) {
        self.continuation = continuation
        self.selfRetain = self

        // 차단 규칙 만드는 데 시간이 걸릴 수 있어 타임아웃부터 걸어 둡니다.
        let timeoutWorkItem = DispatchWorkItem { [weak self] in
            print("❌ 웹뷰 파싱 시간 초과: \(url.absoluteString)")
            self?.finish(with: ParsedItemInfo())
        }
        self.timeoutWorkItem = timeoutWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: timeoutWorkItem)

        observeMemoryPressure()

        Self.makeConfiguration(blocksHeavyResources: blocksHeavyResources) { [weak self] configuration in
            self?.attachWebView(url: url, hostView: hostView, configuration: configuration)
        }
    }

    private func attachWebView(url: URL, hostView: UIView?, configuration: WKWebViewConfiguration) {
        // 규칙을 만드는 사이 타임아웃이 끝났다면 더 진행하지 않습니다.
        guard continuation != nil else { return }

        // 반응형 페이지가 모바일 레이아웃으로 그려지도록 화면 크기를 그대로 씁니다.
        let frame = hostView?.bounds ?? CGRect(x: 0, y: 0, width: 390, height: 844)

        let webView = WKWebView(frame: frame, configuration: configuration)
        webView.navigationDelegate = self
        webView.isUserInteractionEnabled = false
        // 완전히 투명하거나 숨김 상태면 렌더링을 건너뛰는 경우가 있어 아주 옅게만 둡니다.
        webView.alpha = 0.01
        // 맨 뒤에 깔아 둬서 화면에는 보이지 않습니다.
        hostView?.insertSubview(webView, at: 0)
        self.webView = webView

        webView.load(URLRequest(url: url))
    }

    /// 웹뷰 설정을 만듭니다.
    ///
    /// `blocksHeavyResources` 를 켜면 이미지·동영상·폰트를 아예 안 받아 메모리를 크게 아낍니다.
    /// 다만 그걸 기다렸다 내용을 채우는 페이지에서는 값을 못 읽게 되는 부작용이 있어
    /// (쿠팡에서 실제로 그랬습니다) 기본은 꺼 둡니다.
    private static func makeConfiguration(blocksHeavyResources: Bool,
                                          completion: @escaping (WKWebViewConfiguration) -> Void) {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        // 동영상이 저절로 재생되며 메모리를 먹는 것은 항상 막습니다.
        configuration.allowsInlineMediaPlayback = false
        configuration.mediaTypesRequiringUserActionForPlayback = .all

        guard blocksHeavyResources, let store = WKContentRuleListStore.default() else {
            completion(configuration)
            return
        }

        store.compileContentRuleList(forIdentifier: "WishboardMetadataBlocking",
                                     encodedContentRuleList: resourceBlockingRules) { list, error in
            DispatchQueue.main.async {
                if let list = list {
                    configuration.userContentController.add(list)
                } else if let error = error {
                    // 규칙을 못 만들어도 파싱 자체는 되므로 그냥 진행합니다.
                    print("⚠️ 리소스 차단 규칙 생성 실패: \(error.localizedDescription)")
                }
                completion(configuration)
            }
        }
    }

    private static let resourceBlockingRules = """
    [{
      "trigger": { "url-filter": ".*", "resource-type": ["image", "media", "font"] },
      "action": { "type": "block" }
    }]
    """

    /// 메모리가 모자라면 익스텐션이 통째로 죽기 전에 우리가 먼저 포기합니다.
    ///
    /// 포기해도 결과는 '못 가져옴'이라 토스트가 뜰 뿐이지만, 익스텐션이 죽으면
    /// 공유 시트가 통째로 사라져 사용자가 한 작업을 잃습니다. 그쪽이 훨씬 나쁩니다.
    /// 공유 익스텐션에서도 쓸 수 있도록 UIApplication 이 아니라 DispatchSource 로 감시합니다.
    private func observeMemoryPressure() {
        // .warning 은 시스템 전체가 조금만 빠듯해도 올라와서, 멀쩡한 파싱까지 중단시킵니다.
        // 정말 위험한 .critical 에서만 포기합니다.
        let source = DispatchSource.makeMemoryPressureSource(eventMask: .critical, queue: .main)
        source.setEventHandler { [weak self] in
            print("❌ 메모리가 부족해 웹뷰 파싱을 중단합니다.")
            self?.finish(with: ParsedItemInfo())
        }
        source.resume()
        memoryPressureSource = source
    }

    private func finish(with result: ParsedItemInfo) {
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil

        memoryPressureSource?.cancel()
        memoryPressureSource = nil

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

            let (parsed, fallbackTitle) = Self.parse(result)
            let isLastAttempt = self.retryCount >= Self.maxRetryCount

            // og 태그를 하나도 못 찾았으면 아직 안 그려진 것일 수 있어 다시 읽습니다.
            // 페이지 제목(fallbackTitle)은 늘 값이 있으므로 여기서 세면 안 됩니다.
            // 그걸로 성공 판정을 하면 재시도가 한 번도 안 돌고 '쿠팡!' 같은 값이 들어갑니다.
            guard parsed.isEmpty, !isLastAttempt else {
                var result = parsed
                if result.name?.isEmpty ?? true {
                    // 끝까지 og:title 이 없을 때만 페이지 제목을 씁니다. 사이트 이름일 수 있습니다.
                    result.name = fallbackTitle
                }
                print("✅ 웹뷰 파싱 완료 (\(self.retryCount + 1)번째) - 이름: \(result.name ?? "없음") / 가격: \(result.price ?? "없음") / 이미지: \(result.imageUrl ?? "없음")")
                self.finish(with: result)
                return
            }

            print("⏳ og 태그를 아직 못 찾았습니다. 다시 읽습니다. (\(self.retryCount + 1)/\(Self.maxRetryCount))")
            self.retryCount += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.retryInterval) { [weak self] in
                self?.extractMetadata()
            }
        }
    }

    /// - Returns: og 태그/JSON-LD 로 찾은 값과, 최후의 수단인 페이지 제목을 따로 돌려줍니다.
    private static func parse(_ result: Any?) -> (ParsedItemInfo, String?) {
        guard let json = result as? String,
              let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return (ParsedItemInfo(), nil)
        }

        func text(_ key: String) -> String? {
            guard let value = (dict[key] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !value.isEmpty else { return nil }
            return value
        }

        // 가격은 "29,900원" 처럼 올 수 있어 숫자만 남깁니다.
        let price = text("price").map { String($0.filter { $0.isNumber }) }

        let parsed = ParsedItemInfo(name: text("title"),
                                    price: (price?.isEmpty ?? true) ? nil : price,
                                    imageUrl: text("image"))
        return (parsed, text("fallbackTitle"))
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

      // 상대 주소로 온 이미지는 절대 주소로 바꿉니다.
      if (image) {
        try { image = new URL(image, location.href).href; } catch (e) {}
      }

      // 페이지 제목은 늘 값이 있어서 og 결과와 섞으면 안 됩니다.
      // 끝까지 og:title 을 못 찾았을 때만 쓰도록 따로 담아 보냅니다.
      var fallbackTitle = (document.title && document.title.trim()) ? document.title.trim() : null;

      return JSON.stringify({
        title: title,
        image: image,
        price: price,
        fallbackTitle: fallbackTitle
      });
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
        guard let url = navigationAction.request.url,
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            decisionHandler(.cancel)
            return
        }

        // 상품 정보가 없는 중간 안내 페이지라면 실제 상품 주소로 바로 건너뜁니다.
        if let productURL = ShoppingLinkResolver.productURL(skipping: url) {
            print("↪️ 중간 페이지를 건너뜁니다: \(productURL.absoluteString)")
            isSkippingBridgePage = true
            decisionHandler(.cancel)
            webView.load(URLRequest(url: productURL))
            return
        }

        decisionHandler(.allow)
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("🌐 웹뷰가 도착한 주소: \(webView.url?.absoluteString ?? "없음")")
        extractMetadata()
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ 웹뷰 로딩 실패: \(error.localizedDescription)")
        // 일부만 그려졌어도 og 태그는 읽을 수 있어 한 번은 시도해 봅니다.
        extractMetadata()
    }

    /// 웹 프로세스가 메모리 부족 등으로 죽은 경우.
    /// 이대로 두면 타임아웃까지 멍하니 기다리게 되므로 바로 정리합니다.
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        print("❌ 웹뷰 프로세스가 종료되었습니다. (메모리 부족 가능성)")
        finish(with: ParsedItemInfo())
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // 중간 페이지를 건너뛰려고 우리가 취소한 것이면, 새 주소가 곧 로딩되므로 기다립니다.
        if isSkippingBridgePage {
            isSkippingBridgePage = false
            return
        }

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
