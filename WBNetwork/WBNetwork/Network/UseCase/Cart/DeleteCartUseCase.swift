//
//  DeleteCartUseCase.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation

public protocol DeleteCartUseCaseInterface {
    func execute(itemId: Int) async throws -> EmptyResponse
}

public class DeleteCartUseCase: DeleteCartUseCaseInterface {
    private let repository: CartRepositoryInterface
    
    public init(repository: CartRepositoryInterface = CartRepository()) {
        self.repository = repository
    }
    
    public func execute(itemId: Int) async throws -> EmptyResponse {
        return try await self.repository.deleteCart(itemId: itemId)
    }
}
