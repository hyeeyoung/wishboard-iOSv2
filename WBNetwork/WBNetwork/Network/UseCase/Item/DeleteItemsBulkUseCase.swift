//
//  DeleteItemsBulkUseCase.swift
//  WBNetwork
//
//  Created by gomin on 2026/09/20.
//

import Foundation

public protocol DeleteItemsBulkUseCaseInterface {
    func execute(request: BulkDeleteItemsRequest) async throws -> EmptyResponse
}

public class DeleteItemsBulkUseCase: DeleteItemsBulkUseCaseInterface {
    private let repository: ItemRepositoryInterface

    public init(repository: ItemRepositoryInterface = ItemRepository()) {
        self.repository = repository
    }

    public func execute(request: BulkDeleteItemsRequest) async throws -> EmptyResponse {
        return try await self.repository.deleteItemsBulk(request: request)
    }
}
