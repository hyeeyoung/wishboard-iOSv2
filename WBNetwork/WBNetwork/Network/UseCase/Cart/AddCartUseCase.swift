//
//  AddCartUseCase.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation

public protocol AddCartUseCaseInterface {
    func execute(itemId: Int) async throws -> EmptyResponse
}

public class AddCartUseCase: AddCartUseCaseInterface {
    private let repository: CartRepositoryInterface
    
    public init(repository: CartRepositoryInterface = CartRepository()) {
        self.repository = repository
    }
    
    public func execute(itemId: Int) async throws -> EmptyResponse {
        return try await self.repository.addCart(itemId: itemId)
    }
}
