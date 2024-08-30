//
//  LogoutUseCase.swift
//  WBNetwork
//
//  Created by gomin on 8/30/24.
//

import Foundation

public protocol LogoutUseCaseInterface {
    func execute() async throws -> EmptyResponse
}

public class LogoutUseCase: LogoutUseCaseInterface {
    private let repository: AuthRepositoryInterface
    
    public init(repository: AuthRepositoryInterface = AuthRepository()) {
        self.repository = repository
    }
    
    public func execute() async throws -> EmptyResponse {
        return try await self.repository.logout()
    }
}
