//
//  UpdateItemStatusUseCase.swift
//  WBNetwork
//
//  Created by gomin on 3/28/26.
//


import Foundation

public protocol UpdateItemStatusUseCaseInterface {
    func execute(idx: Int, status: ItemStatusType) async throws -> EmptyResponse
}

public class UpdateItemStatusUseCase: UpdateItemStatusUseCaseInterface {
    private let repository: ItemRepositoryInterface
    
    public init(repository: ItemRepositoryInterface = ItemRepository()) {
        self.repository = repository
    }
    
    public func execute(idx: Int, status: ItemStatusType) async throws -> EmptyResponse {
        return try await self.repository.updateItemStatus(idx: idx, status: status)
    }
}
