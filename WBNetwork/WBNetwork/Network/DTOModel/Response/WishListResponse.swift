//
//  WishListResponse.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation

public struct WishListResponse: Decodable {
    public var id: Int?
    public var userId: Int?
    public var folderId: Int?
    public var folderName: String?
    public var itemImages: [ItemImageResponse]?
    public var itemName: String?
    public var itemPrice: String?
    public var itemUrl: String?
    public var itemMemo: String?
    public var itemNotificationType: String?
    public var itemNotificationDate: String?
    public var createdAt: String?
    public var updatedAt: String?
    public var version: Int?
}

public struct ItemImageResponse: Decodable {
    public var itemImg: String?
    public var itemImageUrl: String?
    
    public init(itemImg: String? = nil, itemImageUrl: String? = nil) {
        self.itemImg = itemImg
        self.itemImageUrl = itemImageUrl
    }
}
