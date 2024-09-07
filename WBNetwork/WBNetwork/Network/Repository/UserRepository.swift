//
//  UserRepository.swift
//  WBNetwork
//
//  Created by gomin on 8/24/24.
//

import Foundation

public protocol UserRepositoryInterface {
    func getUserInfo() async throws -> [UserInfoResponse]
    func updatePushState(state: Bool) async throws -> EmptyResponse
    func deleteUser() async throws -> EmptyResponse
    func modifyProfile(profileImg: Data?, nickname: String?) async throws -> EmptyResponse
    func modifyPassword(password: String) async throws -> EmptyResponse
}

public final class UserRepository: UserRepositoryInterface {
    public init() { }
    
    public func getUserInfo() async throws -> [UserInfoResponse] {
        return try await UserAPIManager.shared.getUserInfo()
    }
    
    public func updatePushState(state: Bool) async throws -> EmptyResponse {
        return try await UserAPIManager.shared.updatePushState(state: state)
    }
    
    public func deleteUser() async throws -> EmptyResponse {
        return try await UserAPIManager.shared.deleteUser()
    }
    
    public func modifyProfile(profileImg: Data?, nickname: String?) async throws -> EmptyResponse {
        return try await UserAPIManager.shared.modifyProfile(profileImg: profileImg, nickname: nickname)
    }
    
    public func modifyPassword(password: String) async throws -> EmptyResponse {
        return try await UserAPIManager.shared.modifyPassword(password: password)
    }
}
