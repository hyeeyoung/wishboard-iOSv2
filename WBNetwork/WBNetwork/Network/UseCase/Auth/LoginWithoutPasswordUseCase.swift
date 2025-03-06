//
//  LoginWithoutPasswordUseCase.swift
//  WBNetwork
//
//  Created by gomin on 3/6/25.
//

import Foundation

public protocol LoginWithoutPasswordUseCaseInterface {
    func execute(verify: Bool, email: String, fcmToken: String) async throws -> LoginResponse
}

public class LoginWithoutPasswordUseCase: LoginWithoutPasswordUseCaseInterface {
    private let repository: AuthRepositoryInterface
    
    public init(repository: AuthRepositoryInterface = AuthRepository()) {
        self.repository = repository
    }
    
    public func execute(verify: Bool, email: String, fcmToken: String) async throws -> LoginResponse {
        return try await self.repository.loginWithoutPassword(verify: verify, email: email, fcmToken: fcmToken)
    }
}
