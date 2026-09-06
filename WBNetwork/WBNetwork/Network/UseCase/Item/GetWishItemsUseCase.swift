//
//  GetWishItemsUseCase.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation

public protocol GetWishItemsUseCaseInterface {
    func execute(page: Int, size: Int, itemStatus: ItemStatusType?) async throws -> CommonPaginationResponse<[WishListResponse]>
}

public class GetWishItemsUseCase: GetWishItemsUseCaseInterface {
    private let repository: ItemRepositoryInterface

    public init(repository: ItemRepositoryInterface = ItemRepository()) {
        self.repository = repository
    }

    public func execute(page: Int = 0, size: Int = 10, itemStatus: ItemStatusType? = nil) async throws -> CommonPaginationResponse<[WishListResponse]> {
        return try await self.repository.getWishItems(page: page, size: size, itemStatus: itemStatus)
    }
}

public protocol GetItemCountsUseCaseInterface {
    func execute() async throws -> ItemCountsResponse
}

public class GetItemCountsUseCase: GetItemCountsUseCaseInterface {
    private let repository: ItemRepositoryInterface

    public init(repository: ItemRepositoryInterface = ItemRepository()) {
        self.repository = repository
    }

    public func execute() async throws -> ItemCountsResponse {
        return try await self.repository.getItemCounts()
    }
}
