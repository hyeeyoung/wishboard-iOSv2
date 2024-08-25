//
//  ItemManager.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation

public final class ItemManager {
    public static let shared = ItemManager()
    
    public func getWishItems() async throws -> [WishListResponse] {
        return try await API.Item.requestRaw(.getWishItems)
    }
    
    public func getItemDetail(id: Int) async throws -> [WishListResponse] {
        return try await API.Item.requestRaw(.getItemDetail(id: id))
    }
    
    public func deleteItem(id: Int) async throws -> EmptyResponse {
        return try await API.Item.request(.deleteItem(id: id))
    }
    
    public func modifyItemFolder(itemId: Int, folderId: Int) async throws -> EmptyResponse {
        return try await API.Item.request(.modifyItemFolder(itemId: itemId, folderId: folderId))
    }
}
