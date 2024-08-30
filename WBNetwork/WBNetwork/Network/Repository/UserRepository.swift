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
}

public final class UserRepository: UserRepositoryInterface {
    public init() { }
    
    public func getUserInfo() async throws -> [UserInfoResponse] {
        return try await UserAPIManager.shared.getUserInfo()
    }
    
    public func updatePushState(state: Bool) async throws -> EmptyResponse {
        return try await UserAPIManager.shared.updatePushState(state: state)
    }
}
