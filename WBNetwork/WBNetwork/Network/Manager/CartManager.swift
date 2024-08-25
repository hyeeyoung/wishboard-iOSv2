//
//  CartManager.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation

public final class CartManager {
    public static let shared = CartManager()
    
    public func addCart(itemId: Int) async throws -> EmptyResponse {
        return try await API.Cart.requestRaw(.addCart(itemId: itemId))
    }
    
    public func deleteCart(itemId: Int) async throws -> EmptyResponse {
        return try await API.Cart.requestRaw(.deleteCart(itemId: itemId))
    }
}
