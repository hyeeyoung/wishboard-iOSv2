//
//  DeleteCartUseCase.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation

protocol DeleteCartUseCaseInterface {
    func execute(itemId: Int) async throws -> EmptyResponse
}

class DeleteCartUseCase: DeleteCartUseCaseInterface {
    private let repository: CartRepositoryInterface
    
    init(repository: CartRepositoryInterface = CartRepository()) {
        self.repository = repository
    }
    
    func execute(itemId: Int) async throws -> EmptyResponse {
        return try await self.repository.deleteCart(itemId: itemId)
    }
}
