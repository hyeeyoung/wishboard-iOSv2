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
    
    public func modifyProfile(profileImg: Data?, nickname: String?) async throws -> EmptyResponse {
        return try await API.User.request(.modifyProfile(profileImg: profileImg, nickname: nickname))
    }
    
    public func modifyPassword(password: String) async throws -> EmptyResponse {
        return try await API.User.request(.modifyPassword(password: password))
    }
}
