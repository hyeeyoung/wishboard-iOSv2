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
