//
//  AddCartUseCase.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation

protocol AddCartUseCaseInterface {
    func execute(itemId: Int) async throws -> EmptyResponse
}

class AddCartUseCase: AddCartUseCaseInterface {
    private let repository: CartRepositoryInterface
    
    init(repository: CartRepositoryInterface = CartRepository()) {
        self.repository = repository
    }
    
    func execute(itemId: Int) async throws -> EmptyResponse {
        return try await self.repository.addCart(itemId: itemId)
    }
}
