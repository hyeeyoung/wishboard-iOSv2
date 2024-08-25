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
}
