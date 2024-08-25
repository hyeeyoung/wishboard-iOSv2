//
//  AuthManager.swift
//  WishboardV2
//
//  Created by gomin on 8/12/24.
//

import Foundation

public final class AuthManager {
    static let shared = AuthManager()
    
    func login(email: String, password: String, fcmToken: String) async throws -> LoginResponse {
        try await API.Auth.request(.login(email: email, password: password, fcmToken: fcmToken))
    }
    
    func requestRefreshToken() async throws -> LoginResponse {
        try await API.Auth.request(.requestRefreshToken)
    }
}
