//
//  RefreshTokenUseCase.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation

public protocol RefreshTokenUseCaseInterface {
    func execute() async throws -> LoginResponse
}

public class RefreshTokenUseCase: RefreshTokenUseCaseInterface {
    private let repository: AuthRepositoryInterface
    
    public init(repository: AuthRepositoryInterface = AuthRepository()) {
        self.repository = repository
    }
    
    public func execute() async throws -> LoginResponse {
        return try await self.repository.requestRefreshToken()
    }
}
