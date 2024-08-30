//
//  AuthManagerRepository.swift
//  WishboardV2
//
//  Created by gomin on 8/14/24.
//

import Foundation

public protocol AuthRepositoryInterface {
    func login(email: String, password: String, fcmToken: String) async throws -> LoginResponse
    func requestRefreshToken() async throws -> LoginResponse
    func logout() async throws -> EmptyResponse
}


public final class AuthRepository: AuthRepositoryInterface {
    public init() { }
    
    public func login(email: String, password: String, fcmToken: String) async throws -> LoginResponse {
        return try await AuthManager.shared.login(email: email, password: password, fcmToken: fcmToken)
    }
    
    public func requestRefreshToken() async throws -> LoginResponse {
        return try await AuthManager.shared.requestRefreshToken()
    }
    
    public func logout() async throws -> EmptyResponse {
        return try await AuthManager.shared.logout()
    }
}
