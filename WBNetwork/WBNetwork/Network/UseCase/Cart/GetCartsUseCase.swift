//
//  GetCartsUseCase.swift
//  WBNetwork
//
//  Created by gomin on 8/29/24.
//

import Foundation

public protocol GetCartsUseCaseInterface {
    func execute() async throws -> [CartResponse]
}

public class GetCartsUseCase: GetCartsUseCaseInterface {
    private let repository: CartRepositoryInterface
    
    public init(repository: CartRepositoryInterface = CartRepository()) {
        self.repository = repository
    }
    
    public func execute() async throws -> [CartResponse] {
        return try await self.repository.getCarts()
    }
}
