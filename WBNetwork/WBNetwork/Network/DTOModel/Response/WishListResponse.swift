//
//  WishListResponse.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation

public struct WishListResponse: Decodable {
    public var folder_id: Int?
    public var folder_name: String?
    public var item_id: Int?
    public var item_img_url: String?
    public var item_name: String?
    public var item_price: String?
    public var item_url: String?
    public var item_memo: String?
    public var create_at: String?
    public var item_notification_type: String?
    public var item_notification_date: String?
    public var cart_state: Int?
}
