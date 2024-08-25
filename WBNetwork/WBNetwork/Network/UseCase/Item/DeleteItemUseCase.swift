//
//  DeleteItemUseCase.swift
//  WBNetwork
//
//  Created by gomin on 8/25/24.
//

import Foundation

public protocol DeleteItemUseCaseInterface {
    func execute(id: Int) async throws -> EmptyResponse
}

public class DeleteItemUseCase: DeleteItemUseCaseInterface {
    private let repository: ItemRepositoryInterface
    
    public init(repository: ItemRepositoryInterface = ItemRepository()) {
        self.repository = repository
    }
    
    public func execute(id: Int) async throws -> EmptyResponse {
        return try await self.repository.deleteItem(id: id)
    }
}
