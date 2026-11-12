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

            let head = headPortion(of: data, response: response)
            let baseURL = response.url ?? url
            return parse(head, baseURL: baseURL)
        } catch {
            print("⚠️ HTML 읽기 실패: \(error.localizedDescription)")
            return ParsedItemInfo()
        }
    }

    // MARK: - 디코딩

    /// `</head>` 까지만 잘라 냅니다. 뒤쪽 본문은 볼 필요가 없습니다.
    private static func headPortion(of data: Data, response: URLResponse) -> String {
        let limited = data.prefix(headSearchLimit)
        let html = decode(limited, response: response)

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

    private static func parse(_ html: String, baseURL: URL) -> ParsedItemInfo {
        let name = metaContent(in: html, keys: ["og:title", "twitter:title"])

        let rawImage = metaContent(in: html, keys: ["og:image", "og:image:url", "twitter:image"])
        // 상대 주소로 적힌 이미지는 절대 주소로 바꿉니다.
        let imageUrl = rawImage.flatMap { URL(string: $0, relativeTo: baseURL)?.absoluteString ?? $0 }

        let rawPrice = metaContent(in: html,
                                   keys: ["og:price:amount", "product:price:amount", "price"])
        // "29,900원" 처럼 올 수 있어 숫자만 남깁니다.
        let price = rawPrice.map { String($0.filter { $0.isNumber }) }

        return ParsedItemInfo(name: name,
                              price: (price?.isEmpty ?? true) ? nil : price,
                              imageUrl: imageUrl)
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
