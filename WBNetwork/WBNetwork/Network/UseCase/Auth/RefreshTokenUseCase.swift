//
//  RefreshTokenUseCase.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation

protocol RefreshTokenUseCaseInterface {
    func execute() async throws -> LoginResponse
}

class RefreshTokenUseCase: RefreshTokenUseCaseInterface {
    private let repository: AuthRepositoryInterface
    
    init(repository: AuthRepositoryInterface = AuthRepository()) {
        self.repository = repository
    }
    
    func execute() async throws -> LoginResponse {
        return try await self.repository.requestRefreshToken()
    }
}
