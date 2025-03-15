//
//  ModifyItemUseCase.swift
//  WBNetwork
//
//  Created by gomin on 3/15/25.
//

import Foundation

public protocol ModifyItemUseCaseInterface {
    func execute(idx: Int, item: RequestItemDTO) async throws -> EmptyResponse
}

public class ModifyItemUseCase: ModifyItemUseCaseInterface {
    private let repository: ItemRepositoryInterface
    
    public init(repository: ItemRepositoryInterface = ItemRepository()) {
        self.repository = repository
    }
    
    public func execute(idx: Int, item: RequestItemDTO) async throws -> EmptyResponse {
        return try await self.repository.modifyItem(idx: idx, item: item)
    }
}
