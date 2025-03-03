//
//  VersionRepository.swift
//  WBNetwork
//
//  Created by gomin on 3/3/25.
//

import Foundation

public protocol VersionRepositoryInterface {
    func getVersion() async throws -> VersionResponse
}

public final class VersionRepository: VersionRepositoryInterface {
    public init() { }
    
    public func getVersion() async throws -> VersionResponse {
        return try await VersionManager.shared.getVersion()
    }
}
