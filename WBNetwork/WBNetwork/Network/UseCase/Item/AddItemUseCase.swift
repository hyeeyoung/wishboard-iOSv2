//
//  AddItemUseCase.swift
//  WBNetwork
//
//  Created by gomin on 9/1/24.
//

import Foundation

public protocol AddItemUseCaseInterface {
    func execute(type: AddItemType, item: RequestItemDTO) async throws -> EmptyResponse
}

public class AddItemUseCase: AddItemUseCaseInterface {
    private let repository: ItemRepositoryInterface
    
    public init(repository: ItemRepositoryInterface = ItemRepository()) {
        self.repository = repository
    }
    
    public func execute(type: AddItemType, item: RequestItemDTO) async throws -> EmptyResponse {
        return try await self.repository.addItem(type: type, item: item)
    }
}
