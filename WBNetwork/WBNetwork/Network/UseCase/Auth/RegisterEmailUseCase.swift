//
//  RegisterEmailUseCase.swift
//  WBNetwork
//
//  Created by gomin on 3/6/25.
//

import Foundation


public protocol RegisterEmailUseCaseInterface {
    func execute(email: String) async throws -> EmptyResponse
}

public class RegisterEmailUseCase: RegisterEmailUseCaseInterface {
    private let repository: AuthRepositoryInterface
    
    public init(repository: AuthRepositoryInterface = AuthRepository()) {
        self.repository = repository
    }
    
    public func execute(email: String) async throws -> EmptyResponse {
        return try await self.repository.registerEmail(email: email)
    }
}
