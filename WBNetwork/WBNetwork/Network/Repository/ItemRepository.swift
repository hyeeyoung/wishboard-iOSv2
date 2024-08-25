//
//  ItemRepository.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation

public protocol ItemRepositoryInterface {
    func getWishItems() async throws -> [WishListResponse]
}

public final class ItemRepository: ItemRepositoryInterface {
    public init() { }
    
    public func getWishItems() async throws -> [WishListResponse] {
        return try await ItemManager.shared.getWishItems()
    }
}
