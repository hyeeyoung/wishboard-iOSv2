//
//  HTMLMetadataLoader.swift
//  WishboardV2
//
//  Created by gomin on 11/12/26.
//

import UIKit

/// 페이지 HTML 을 받아 `<head>` 의 og 태그를 읽습니다.
///
/// 웹뷰를 띄우기 전에 거치는 단계입니다. og 태그는 문서 맨 앞에 있어서 페이지를 실제로
/// 그릴 필요가 없는데, 웹뷰는 DOM 을 만들고 스크립트까지 돌리느라 메모리를 훨씬 많이 씁니다.
///
/// 쇼핑몰 빌더로 만든 페이지 중에는 상품 데이터를 스크립트에 통째로 박아 넣어 HTML 이
/// 1MB 를 넘는 것들이 있습니다. 그런 페이지를 웹뷰로 열면 메모리 한도가 낮은 공유
/// 익스텐션이 통째로 종료됩니다. 실제로 sixshop 상품 페이지가 1.4MB 였는데, 정작
/// 필요한 og 태그는 앞쪽 5KB 안에 있었습니다.
///
/// 봇 차단을 하는 사이트는 여기서 실패하므로, 그때만 웹뷰로 넘어갑니다.
public enum HTMLMetadataLoader {

    public static let defaultTimeout: TimeInterval = 8

    /// og 태그를 찾을 범위. `</head>` 를 못 찾았을 때의 상한입니다.
    private static let headSearchLimit = 256 * 1024

    /// - Returns: 실패하더라도 에러를 던지지 않고 빈 값을 돌려줍니다.
    public static func load(from urlString: String,
                            timeout: TimeInterval = defaultTimeout) async -> ParsedItemInfo {
        guard let url = URL(string: urlString),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return ParsedItemInfo()
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = timeout

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                print("⚠️ HTML 읽기 실패: HTTP \(http.statusCode)")
                return ParsedItemInfo()
            }

            let document = decode(data.prefix(headSearchLimit), response: response)
            let baseURL = response.url ?? url
            return parse(head: headPortion(of: document), document: document, baseURL: baseURL)
        } catch {
            print("⚠️ HTML 읽기 실패: \(error.localizedDescription)")
            return ParsedItemInfo()
        }
    }

    // MARK: - 디코딩

    /// `</head>` 까지만 잘라 냅니다. meta 태그는 전부 여기 있습니다.
    private static func headPortion(of html: String) -> String {
        guard let headEnd = html.range(of: "</head>", options: .caseInsensitive) else {
            return html
        }
        return String(html[html.startIndex..<headEnd.upperBound])
    }

    /// 국내 쇼핑몰 중에는 아직 EUC-KR 로 내려주는 곳이 있어 인코딩을 확인합니다.
    private static func decode(_ data: Data, response: URLResponse) -> String {
        // 앞부분만 ASCII 로 훑어 charset 을 찾습니다.
        let probe = String(decoding: data.prefix(4096), as: UTF8.self).lowercased()
        let charset = response.textEncodingName?.lowercased()
            ?? (probe.contains("euc-kr") ? "euc-kr" : nil)

        if let charset = charset, charset.contains("euc-kr") || charset.contains("ks_c_5601") {
            let encoding = CFStringConvertEncodingToNSStringEncoding(
                CFStringEncoding(CFStringEncodings.EUC_KR.rawValue)
            )
            if let text = String(data: data, encoding: String.Encoding(rawValue: encoding)) {
                return text
            }
        }

        // 잘린 지점에서 깨진 바이트가 있어도 대체 문자로 넘어갑니다.
        return String(decoding: data, as: UTF8.self)
    }

    // MARK: - 파싱

    private static func parse(head: String, document: String, baseURL: URL) -> ParsedItemInfo {
        var info = ParsedItemInfo(
            name: metaContent(in: head, keys: ["og:title", "twitter:title"]),
            price: digitsOnly(metaContent(in: head,
                                          keys: ["og:price:amount", "product:price:amount", "price"])),
            imageUrl: metaContent(in: head, keys: ["og:image", "og:image:url", "twitter:image"])
        )

        // 가격을 og 태그에 안 쓰고 JSON-LD 에만 넣는 쇼핑몰이 많습니다.
        // meta 로 못 채운 값만 거기서 가져옵니다.
        if info.name == nil || info.price == nil || info.imageUrl == nil {
            info.merge(productFromJSONLD(in: document))
        }

        // 상대 주소로 적힌 이미지는 절대 주소로 바꿉니다.
        if let image = info.imageUrl {
            info.imageUrl = URL(string: image, relativeTo: baseURL)?.absoluteString ?? image
        }
        return info
    }

    /// "29,900원" 처럼 올 수 있어 숫자만 남깁니다.
    private static func digitsOnly(_ value: String?) -> String? {
        guard let digits = value.map({ String($0.filter { $0.isNumber }) }), !digits.isEmpty else {
            return nil
        }
        return digits
    }

    // MARK: - JSON-LD

    /// `<script type="application/ld+json">` 안의 Product 정보를 읽습니다.
    private static func productFromJSONLD(in html: String) -> ParsedItemInfo {
        let pattern = "<script[^>]*application/ld\\+json[^>]*>([\\s\\S]*?)</script>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return ParsedItemInfo()
        }

        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        for match in regex.matches(in: html, range: range) {
            guard match.numberOfRanges > 1,
                  let bodyRange = Range(match.range(at: 1), in: html),
                  let data = String(html[bodyRange]).data(using: .utf8),
                  let root = try? JSONSerialization.jsonObject(with: data) else { continue }

            for product in productNodes(in: root) {
                let info = ParsedItemInfo(name: product["name"] as? String,
                                          price: digitsOnly(priceText(in: product["offers"])),
                                          imageUrl: imageText(in: product["image"]))
                if !info.isEmpty { return info }
            }
        }
        return ParsedItemInfo()
    }

    /// 최상위가 배열이거나 `@graph` 로 감싸인 경우까지 펼쳐서 Product 만 추립니다.
    private static func productNodes(in root: Any) -> [[String: Any]] {
        var queue: [Any] = [root]
        var products: [[String: Any]] = []

        while let current = queue.popLast() {
            if let array = current as? [Any] {
                queue.append(contentsOf: array)
                continue
            }
            guard let node = current as? [String: Any] else { continue }

            if let graph = node["@graph"] {
                queue.append(graph)
            }
            if isProduct(node["@type"]) {
                products.append(node)
            }
        }
        return products
    }

    private static func isProduct(_ type: Any?) -> Bool {
        if let single = type as? String {
            return single.caseInsensitiveCompare("Product") == .orderedSame
        }
        if let many = type as? [String] {
            return many.contains { $0.caseInsensitiveCompare("Product") == .orderedSame }
        }
        return false
    }

    /// 이미지는 문자열, 배열, `{ "url": ... }` 중 아무 형태로나 올 수 있습니다.
    private static func imageText(in value: Any?) -> String? {
        if let text = value as? String { return text }
        if let list = value as? [Any] {
            return list.compactMap { imageText(in: $0) }.first
        }
        if let node = value as? [String: Any] { return node["url"] as? String }
        return nil
    }

    /// offers 도 하나일 수도, 배열일 수도 있습니다.
    private static func priceText(in offers: Any?) -> String? {
        let candidates: [Any]
        if let list = offers as? [Any] { candidates = list }
        else if let offers = offers { candidates = [offers] }
        else { return nil }

        for candidate in candidates {
            guard let offer = candidate as? [String: Any] else { continue }
            // 범위로 적는 곳이 있어 lowPrice 도 봅니다.
            for key in ["price", "lowPrice"] {
                if let text = offer[key] as? String, !text.isEmpty { return text }
                if let number = offer[key] as? NSNumber { return number.stringValue }
            }
        }
        return nil
    }

    private static func metaContent(in html: String, keys: [String]) -> String? {
        for key in keys {
            let escaped = NSRegularExpression.escapedPattern(for: key)
            // content 가 앞에 오는 경우와 뒤에 오는 경우를 모두 봅니다.
            let patterns = [
                "<meta[^>]+(?:property|name|itemprop)=[\"']\(escaped)[\"'][^>]*?content=[\"']([^\"']*)[\"']",
                "<meta[^>]+content=[\"']([^\"']*)[\"'][^>]*?(?:property|name|itemprop)=[\"']\(escaped)[\"']"
            ]

            for pattern in patterns {
                if let value = firstCapture(of: pattern, in: html) {
                    let trimmed = value.decodingBasicHTMLEntities
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty { return trimmed }
                }
            }
        }
        return nil
    }

    private static func firstCapture(of pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              match.numberOfRanges > 1,
              let captured = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[captured])
    }
}

private extension String {
    /// og 태그 값에 자주 섞여 들어오는 것만 풀어 줍니다.
    var decodingBasicHTMLEntities: String {
        var result = self
        let entities = [
            ("&lt;", "<"), ("&gt;", ">"), ("&quot;", "\""),
            ("&#39;", "'"), ("&apos;", "'"), ("&nbsp;", " "),
            ("&amp;", "&")   // 다른 것들을 먼저 풀어야 해서 마지막에 둡니다.
        ]
        for (entity, character) in entities {
            result = result.replacingOccurrences(of: entity, with: character)
        }
        return result
    }
}
