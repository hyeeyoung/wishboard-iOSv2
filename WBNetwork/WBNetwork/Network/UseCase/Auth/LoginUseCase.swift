//
//  AuthUseCaseUseCase.swift
//  WishboardV2
//
//  Created by gomin on 8/14/24.
//

import Foundation

public protocol LoginUseCaseInterface {
    func execute(email: String, password: String, fcmToken: String) async throws -> LoginResponse
}

public class LoginUseCase: LoginUseCaseInterface {
    private let repository: AuthRepositoryInterface
    
    public init(repository: AuthRepositoryInterface = AuthRepository()) {
        self.repository = repository
    }
    
    public func execute(email: String, password: String, fcmToken: String) async throws -> LoginResponse {
        return try await self.repository.login(email: email, password: password, fcmToken: fcmToken)
    }
}
