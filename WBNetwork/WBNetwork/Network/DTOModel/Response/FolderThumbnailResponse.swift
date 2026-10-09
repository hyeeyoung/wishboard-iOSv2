//
//  FolderThumbnailResponse.swift
//  WBNetwork
//
//  Created by gomin on 10/9/26.
//

import Foundation

/// 폴더 대표 사진으로 고를 수 있는 이미지 한 장.
///
/// 폴더에 담긴 아이템마다 첫 번째 이미지를 내려주며, 이미지가 없는 아이템은 빠집니다.
public struct FolderThumbnailImageResponse: Decodable {
    public var itemId: Int?
    /// 대표 사진 지정 시 서버에 보내는 값
    public var itemImageId: Int?
    public var itemImageUrl: String?
    /// 현재 적용된 대표 사진 하나에만 true 입니다.
    public var selected: Bool?

    public init(itemId: Int? = nil, itemImageId: Int? = nil, itemImageUrl: String? = nil, selected: Bool? = nil) {
        self.itemId = itemId
        self.itemImageId = itemImageId
        self.itemImageUrl = itemImageUrl
        self.selected = selected
    }
}

/// 대표 사진 지정/해제 후 적용된 대표 사진
public struct FolderThumbnailResponse: Decodable {
    /// 적용된 대표 사진. 이미지가 있는 아이템이 없으면 nil 입니다.
    public var folderThumbnail: String?

    public init(folderThumbnail: String? = nil) {
        self.folderThumbnail = folderThumbnail
    }
}
