//
//  FolderRepository.swift
//  WBNetwork
//
//  Created by gomin on 8/18/24.
//

import Foundation

public protocol FolderRepositoryInterface {
    func getFolders() async throws -> [FolderListResponse]
}

public final class FolderRepository: FolderRepositoryInterface {
    public init() { }
    
    public func getFolders() async throws -> [FolderListResponse] {
        return try await FolderManager.shared.getFolders()
    }
}
