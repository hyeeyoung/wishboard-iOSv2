//
//  AuthUseCaseUseCase.swift
//  WishboardV2
//
//  Created by gomin on 8/14/24.
//

import Foundation

protocol LoginUseCaseInterface {
    func execute(email: String, password: String, fcmToken: String) async throws -> LoginResponse
}

class LoginUseCase: LoginUseCaseInterface {
    private let repository: AuthRepositoryInterface
    
    init(repository: AuthRepositoryInterface = AuthRepository()) {
        self.repository = repository
    }
    
    func execute(email: String, password: String, fcmToken: String) async throws -> LoginResponse {
        return try await self.repository.login(email: email, password: password, fcmToken: fcmToken)
    }
}
