//
//  GetWishItemsUseCase.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation

public protocol GetWishItemsUseCaseInterface {
    func execute(page: Int, size: Int) async throws -> CommonPaginationResponse<[WishListResponse]>
}

public class GetWishItemsUseCase: GetWishItemsUseCaseInterface {
    private let repository: ItemRepositoryInterface
    
    public init(repository: ItemRepositoryInterface = ItemRepository()) {
        self.repository = repository
    }
    
    public func execute(page: Int = 0, size: Int = 10) async throws -> CommonPaginationResponse<[WishListResponse]> {
        return try await self.repository.getWishItems(page: page, size: size)
    }
}
