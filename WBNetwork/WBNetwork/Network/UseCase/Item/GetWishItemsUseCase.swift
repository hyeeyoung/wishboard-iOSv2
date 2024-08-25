//
//  GetWishItemsUseCase.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation

protocol GetWishItemsUseCaseInterface {
    func execute() async throws -> [WishListResponse]
}

class GetWishItemsUseCase: GetWishItemsUseCaseInterface {
    private let repository: ItemRepositoryInterface
    
    init(repository: ItemRepositoryInterface = ItemRepository()) {
        self.repository = repository
    }
    
    func execute() async throws -> [WishListResponse] {
        return try await self.repository.getWishItems()
    }
}
