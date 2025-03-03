//
//  VersionManager.swift
//  WBNetwork
//
//  Created by gomin on 3/3/25.
//

import Foundation

public final class VersionManager {
    public static let shared = VersionManager()
    
    public func getVersion() async throws -> VersionResponse {
        return try await API.Version.request(.getVersion)
    }
}
