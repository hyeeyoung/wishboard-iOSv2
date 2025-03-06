//
//  AuthManagerRepository.swift
//  WishboardV2
//
//  Created by gomin on 8/14/24.
//

import Foundation

public protocol AuthRepositoryInterface {
    func login(email: String, password: String, fcmToken: String) async throws -> LoginResponse
    func requestRefreshToken(token: String) async throws -> LoginResponse
    func logout() async throws -> EmptyResponse
    func emailLogin(email: String) async throws -> CommonResponse<EmailLoginResponse>
}


public final class AuthRepository: AuthRepositoryInterface {
    public init() { }
    
    public func login(email: String, password: String, fcmToken: String) async throws -> LoginResponse {
        return try await AuthManager.shared.login(email: email, password: password, fcmToken: fcmToken)
    }
    
    public func requestRefreshToken(token: String) async throws -> LoginResponse {
        return try await AuthManager.shared.requestRefreshToken(token: token)
    }
    
    public func logout() async throws -> EmptyResponse {
        return try await AuthManager.shared.logout()
    }
    
    public func emailLogin(email: String) async throws -> CommonResponse<EmailLoginResponse> {
        return try await AuthManager.shared.emailLogin(email: email)
    }
}
