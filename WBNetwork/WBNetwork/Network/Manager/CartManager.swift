//
//  CartManager.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation

public final class CartManager {
    static let shared = CartManager()
    
    func addCart(itemId: Int) async throws -> EmptyResponse {
        return try await API.Cart.requestRaw(.addCart(itemId: itemId))
    }
    
    func deleteCart(itemId: Int) async throws -> EmptyResponse {
        return try await API.Cart.requestRaw(.deleteCart(itemId: itemId))
    }
}
