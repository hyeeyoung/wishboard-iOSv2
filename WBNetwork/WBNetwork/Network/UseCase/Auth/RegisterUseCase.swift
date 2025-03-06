//
//  RegisterUseCase.swift
//  WBNetwork
//
//  Created by gomin on 3/6/25.
//

import Foundation

public protocol RegisterUseCaseInterface {
    func execute(email: String, password: String, fcmToken: String) async throws -> LoginResponse
}

public class RegisterUseCase: RegisterUseCaseInterface {
    private let repository: AuthRepositoryInterface
    
    public init(repository: AuthRepositoryInterface = AuthRepository()) {
        self.repository = repository
    }
    
    public func execute(email: String, password: String, fcmToken: String) async throws -> LoginResponse {
        return try await self.repository.signUp(email: email, password: password, fcmToken: fcmToken)
    }
}
