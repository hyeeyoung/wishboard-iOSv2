//
//  AuthManager.swift
//  WishboardV2
//
//  Created by gomin on 8/12/24.
//

import Foundation

public final class AuthManager {
    public static let shared = AuthManager()
    
    public func login(email: String, password: String, fcmToken: String) async throws -> LoginResponse {
        try await API.Auth.request(.login(email: email, password: password, fcmToken: fcmToken))
    }
    
    public func requestRefreshToken(token: String) async throws -> LoginResponse {
        try await API.Auth.request(.requestRefreshToken(token: token))
    }
    
    public func logout() async throws -> EmptyResponse {
        try await API.Auth.request(.logout)
    }
    
    public func emailLogin(email: String) async throws -> CommonResponse<EmailLoginResponse> {
        try await API.Auth.requestRaw(.emailLogin(email: email))
    }
    
    public func registerEmail(email: String) async throws -> EmptyResponse {
        try await API.Auth.request(.registerEmail(email: email))
    }
}
