//
//  UserManager.swift
//  WBNetwork
//
//  Created by gomin on 8/24/24.
//

import Foundation

public final class UserAPIManager {
    public static let shared = UserAPIManager()
    
    public func getUserInfo() async throws -> [UserInfoResponse] {
        return try await API.User.requestRaw(.getUserInfo)
    }
    
    public func updatePushState(state: Bool) async throws -> EmptyResponse {
        return try await API.User.request(.updatePushState(state: state))
    }
    
    public func deleteUser() async throws -> EmptyResponse {
        return try await API.User.request(.deleteUser)
    }
}
