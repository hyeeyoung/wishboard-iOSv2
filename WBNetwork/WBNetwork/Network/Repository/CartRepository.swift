//
//  CartRepository.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation

protocol CartRepositoryInterface {
    func addCart(itemId: Int) async throws -> EmptyResponse
    func deleteCart(itemId: Int) async throws -> EmptyResponse
}

final class CartRepository: CartRepositoryInterface {
    
    func addCart(itemId: Int) async throws -> EmptyResponse {
        return try await CartManager.shared.addCart(itemId: itemId)
    }
    
    func deleteCart(itemId: Int) async throws -> EmptyResponse {
        return try await CartManager.shared.deleteCart(itemId: itemId)
    }
}
