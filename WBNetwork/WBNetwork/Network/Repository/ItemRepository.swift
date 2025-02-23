//
//  ItemRepository.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation

public protocol ItemRepositoryInterface {
    func getWishItems() async throws -> [WishListResponse]
    func deleteItem(id: Int) async throws -> EmptyResponse
    func getItemDetail(id: Int) async throws -> WishListResponse
    func modifyItemFolder(itemId: Int, folderId: Int) async throws -> EmptyResponse
    func parseItemUrl(link: String) async throws -> WishListResponse
    func addItem(type: AddItemType, item: RequestItemDTO) async throws -> EmptyResponse
}

public final class ItemRepository: ItemRepositoryInterface {
    public init() { }
    
    public func getWishItems() async throws -> [WishListResponse] {
        return try await ItemManager.shared.getWishItems()
    }
    
    public func deleteItem(id: Int) async throws -> EmptyResponse {
        return try await ItemManager.shared.deleteItem(id: id)
    }
    
    public func getItemDetail(id: Int) async throws -> WishListResponse {
        let data = try await ItemManager.shared.getItemDetail(id: id)
        return data[0]
    }
    
    public func modifyItemFolder(itemId: Int, folderId: Int) async throws -> EmptyResponse {
        return try await ItemManager.shared.modifyItemFolder(itemId: itemId, folderId: folderId)
    }
    
    public func parseItemUrl(link: String) async throws -> WishListResponse {
        return try await ItemManager.shared.parseItemUrl(link: link)
    }
    
    public func addItem(type: AddItemType, item: RequestItemDTO) async throws -> EmptyResponse {
        return try await ItemManager.shared.addItem(type: type, item: item)
    }
}
