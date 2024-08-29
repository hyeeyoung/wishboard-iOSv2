//
//  CartResponse.swift
//  WBNetwork
//
//  Created by gomin on 8/29/24.
//

import Foundation

public struct CartResponse: Decodable {
    public let wishItem: CartItemModel?
    public let cartItemInfo: CartItemCountModel?
}

public struct CartItemModel: Decodable {
    public let folder_id: Int?
    public let folder_name: String?
    public let item_id: Int?
    public let item_img: String?
    public let item_name: String?
    public let item_price: String?
    public let item_url: String?
    public let item_memo: String?
    public let create_at: String?
    public let item_notification_type: String?
    public let item_notification_date: String?
    public let cart_state: Int?
}

public struct CartItemCountModel: Decodable {
    public let item_count: Int?
}
