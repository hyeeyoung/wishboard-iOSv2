//
//  FolderManager.swift
//  WBNetwork
//
//  Created by gomin on 8/18/24.
//

import Foundation

public final class FolderManager {
    public static let shared = FolderManager()
    
    public func getFolders() async throws -> [FolderListResponse] {
        return try await API.Folder.requestRaw(.getFolders)
    }
}
