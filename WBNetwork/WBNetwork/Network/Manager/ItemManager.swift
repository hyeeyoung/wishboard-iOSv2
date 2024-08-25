//
//  ItemManager.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation

public final class ItemManager {
    static let shared = ItemManager()
    
    func getWishItems() async throws -> [WishListResponse] {
        return try await API.Item.requestRaw(.getWishItems)
    }
}
