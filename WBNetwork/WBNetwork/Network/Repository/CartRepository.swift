//
//  CartRepository.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation

public protocol CartRepositoryInterface {
    func addCart(itemId: Int) async throws -> EmptyResponse
    func deleteCart(itemId: Int) async throws -> EmptyResponse
}

public final class CartRepository: CartRepositoryInterface {
    public init() { }
    
    public func addCart(itemId: Int) async throws -> EmptyResponse {
        return try await CartManager.shared.addCart(itemId: itemId)
    }
    
    public func deleteCart(itemId: Int) async throws -> EmptyResponse {
        return try await CartManager.shared.deleteCart(itemId: itemId)
    }
}
