//
//  GetItemDetailUseCase.swift
//  WBNetwork
//
//  Created by gomin on 8/25/24.
//

import Foundation

public protocol GetItemDetailUseCaseInterface {
    func execute(id: Int) async throws -> WishListResponse
}

public class GetItemDetailUseCase: GetItemDetailUseCaseInterface {
    private let repository: ItemRepositoryInterface
    
    public init(repository: ItemRepositoryInterface = ItemRepository()) {
        self.repository = repository
    }
    
    public func execute(id: Int) async throws -> WishListResponse {
        return try await self.repository.getItemDetail(id: id)
    }
}
