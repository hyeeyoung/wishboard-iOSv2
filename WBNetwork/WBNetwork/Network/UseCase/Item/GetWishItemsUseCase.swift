//
//  GetWishItemsUseCase.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation

public protocol GetWishItemsUseCaseInterface {
    func execute() async throws -> [WishListResponse]
}

public class GetWishItemsUseCase: GetWishItemsUseCaseInterface {
    private let repository: ItemRepositoryInterface
    
    public init(repository: ItemRepositoryInterface = ItemRepository()) {
        self.repository = repository
    }
    
    public func execute() async throws -> [WishListResponse] {
        return try await self.repository.getWishItems()
    }
}
