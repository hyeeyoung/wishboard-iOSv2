//
//  ModifyCartQuantityUseCase.swift
//  WBNetwork
//
//  Created by gomin on 8/29/24.
//

import Foundation

public protocol ModifyCartQuantityUseCaseInterface{
    func execute(itemId: Int, itemCount: Int) async throws -> EmptyResponse
}

public class ModifyCartQuantityUseCase: ModifyCartQuantityUseCaseInterface {
    private let repository: CartRepositoryInterface
    
    public init(repository: CartRepositoryInterface = CartRepository()) {
        self.repository = repository
    }
    
    public func execute(itemId: Int, itemCount: Int) async throws -> EmptyResponse {
        return try await self.repository.modifyCartQuantity(itemId: itemId, itemCount: itemCount)
    }
}
