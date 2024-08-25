//
//  AuthManagerRepository.swift
//  WishboardV2
//
//  Created by gomin on 8/14/24.
//

import Foundation

protocol AuthRepositoryInterface {
    func login(email: String, password: String, fcmToken: String) async throws -> LoginResponse
    func requestRefreshToken() async throws -> LoginResponse
}


final class AuthRepository: AuthRepositoryInterface {
    func login(email: String, password: String, fcmToken: String) async throws -> LoginResponse {
        return try await AuthManager.shared.login(email: email, password: password, fcmToken: fcmToken)
    }
    
    func requestRefreshToken() async throws -> LoginResponse {
        return try await AuthManager.shared.requestRefreshToken()
    }
}
