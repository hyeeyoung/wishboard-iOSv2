//
//  ItemRepository.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation

protocol ItemRepositoryInterface {
    func getWishItems() async throws -> [WishListResponse]
}

final class ItemRepository: ItemRepositoryInterface {
    func getWishItems() async throws -> [WishListResponse] {
        return try await ItemManager.shared.getWishItems()
    }
}
