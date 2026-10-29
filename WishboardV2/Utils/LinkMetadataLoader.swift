//
//  LinkMetadataLoader.swift
//  WishboardV2
//
//  Created by gomin on 10/27/26.
//

import UIKit
import LinkPresentation
import UniformTypeIdentifiers

/// 애플 LinkPresentation 으로 가져온 링크 미리보기 정보
public struct LinkMetadata {
    public let title: String?
    public let image: UIImage?

    public init(title: String? = nil, image: UIImage? = nil) {
        self.title = title
        self.image = image
    }

    public var isEmpty: Bool {
        (title?.isEmpty ?? true) && image == nil
    }
}

/// 쇼핑몰 링크에서 제목과 대표 이미지를 가져옵니다.
///
/// 서버 파싱이 상품 정보를 못 가져왔을 때(204) 보완용으로만 씁니다.
/// LinkPresentation 은 og 태그 기반이라 제목과 이미지까지만 주고, **가격은 제공하지 않습니다.**
public enum LinkMetadataLoader {

    /// 공유 익스텐션에서도 쓰는 만큼, 사용자를 오래 기다리게 하지 않도록 짧게 잡습니다.
    public static let defaultTimeout: TimeInterval = 10

    /// - Returns: 실패하더라도 에러를 던지지 않고 빈 값을 돌려줍니다. 어디까지나 보완 수단이기 때문입니다.
    public static func load(from urlString: String, timeout: TimeInterval = defaultTimeout) async -> LinkMetadata {
        guard let url = URL(string: urlString),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return LinkMetadata()
        }

        // LPMetadataProvider 는 인스턴스당 한 번만 사용할 수 있어 매번 새로 만듭니다.
        let provider = LPMetadataProvider()
        provider.timeout = timeout

        do {
            let metadata = try await provider.startFetchingMetadata(for: url)
            let title = metadata.title?.trimmingCharacters(in: .whitespacesAndNewlines)
            // 대표 이미지가 없으면 파비콘이라도 씁니다.
            let image = await loadImage(from: metadata.imageProvider ?? metadata.iconProvider)

            return LinkMetadata(title: (title?.isEmpty ?? true) ? nil : title, image: image)
        } catch {
            print("❌ 링크 미리보기 조회 실패: \(error.localizedDescription)")
            return LinkMetadata()
        }
    }

    private static func loadImage(from provider: NSItemProvider?) async -> UIImage? {
        guard let provider = provider else { return nil }

        if provider.canLoadObject(ofClass: UIImage.self) {
            return await withCheckedContinuation { continuation in
                _ = provider.loadObject(ofClass: UIImage.self) { object, _ in
                    continuation.resume(returning: object as? UIImage)
                }
            }
        }

        return await withCheckedContinuation { continuation in
            _ = provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                continuation.resume(returning: data.flatMap { UIImage(data: $0) })
            }
        }
    }
}

/// 아이템 등록 화면에 채울 상품 정보 한 건.
///
/// 서버 파싱 결과와, 서버가 못 가져왔을 때 LinkPresentation 으로 보완한 결과를 함께 담습니다.
/// 이미지는 서버가 준 주소(`imageUrl`) 이거나 링크 미리보기에서 바로 받은 이미지(`image`) 입니다.
public struct ParsedItemInfo {
    public var name: String?
    public var price: String?
    public var imageUrl: String?
    public var image: UIImage?

    public init(name: String? = nil, price: String? = nil, imageUrl: String? = nil, image: UIImage? = nil) {
        self.name = name
        self.price = price
        self.imageUrl = imageUrl
        self.image = image
    }

    /// 이름 / 가격 / 이미지 중 하나도 못 가져왔는지 여부
    public var isEmpty: Bool {
        (name?.isEmpty ?? true)
            && (price?.isEmpty ?? true)
            && (imageUrl?.isEmpty ?? true)
            && image == nil
    }

    /// 비어 있는 값만 다른 파싱 결과로 채웁니다.
    public mutating func merge(_ other: ParsedItemInfo) {
        if name?.isEmpty ?? true {
            name = other.name
        }
        if price?.isEmpty ?? true {
            price = other.price
        }
        if (imageUrl?.isEmpty ?? true), image == nil {
            imageUrl = other.imageUrl
            image = other.image
        }
    }

    /// 비어 있는 값만 링크 미리보기 값으로 채웁니다.
    /// 가격은 LinkPresentation 이 주지 않아 그대로 둡니다.
    public mutating func fill(with metadata: LinkMetadata) {
        if name?.isEmpty ?? true {
            name = metadata.title
        }
        if (imageUrl?.isEmpty ?? true), image == nil {
            image = metadata.image
        }
    }
}

/// 단축 링크나 중간 안내 페이지 주소를 실제 상품 주소로 펼칩니다.
///
/// 서버에 보낼 주소, 웹뷰가 열 주소, 아이템에 저장될 주소가 모두 이걸 거칩니다.
/// 저장되는 주소까지 바뀌어야 나중에 상세 화면에서 링크를 열 때도 중간 페이지로
/// 새지 않습니다.
public enum ShoppingLinkResolver {

    /// 펼쳐야 하는 단축 주소 호스트
    private static let shortenerHosts: Set<String> = ["naver.me", "link.coupang.com"]

    private static let timeout: TimeInterval = 5

    /// - Returns: 펼치지 못하면 받은 주소를 그대로 돌려줍니다.
    public static func resolve(_ urlString: String) async -> String {
        let expanded = await expandIfShortened(urlString)

        guard let url = URL(string: expanded), let product = productURL(skipping: url) else {
            return expanded
        }
        print("↪️ 중간 안내 페이지를 건너뜁니다: \(product.absoluteString)")
        return product.absoluteString
    }

    private static func expandIfShortened(_ urlString: String) async -> String {
        guard let url = URL(string: urlString),
              let host = url.host?.lowercased(),
              shortenerHosts.contains(host) else {
            return urlString
        }

        var request = URLRequest(url: url)
        // 본문은 필요 없고 최종 주소만 알면 됩니다.
        request.httpMethod = "HEAD"
        request.timeoutInterval = timeout

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let resolved = response.url?.absoluteString, !resolved.isEmpty else {
                return urlString
            }
            print("↪️ 단축 링크를 펼쳤습니다: \(resolved)")
            return resolved
        } catch {
            print("⚠️ 단축 링크 펼치기 실패: \(error.localizedDescription)")
            return urlString
        }
    }

    /// 네이버 단축 링크는 모바일에서 app-bridge 라는 중간 페이지로 갑니다.
    /// 그 페이지에는 상품 정보가 없고(og:title 이 "네이버+ 스토어") 앱을 띄우는 커스텀 스킴만
    /// 들어 있습니다. 실제 상품 주소는 url 파라미터에 담겨 있습니다.
    /// - Returns: 중간 페이지가 아니면 nil
    public static func productURL(skipping url: URL) -> URL? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.host?.lowercased() == "app.shopping.naver.com",
              components.path.contains("app-bridge"),
              let target = components.queryItems?.first(where: { $0.name == "url" })?.value,
              let productURL = URL(string: target),
              let scheme = productURL.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return nil
        }
        return productURL
    }
}
