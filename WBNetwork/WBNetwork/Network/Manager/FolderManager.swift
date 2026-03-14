//
//  FolderManager.swift
//  WBNetwork
//
//  Created by gomin on 8/18/24.
//

import Foundation

public final class FolderManager {
    public static let shared = FolderManager()
    
    public func getFolders(page: Int = 0, size: Int = 10) async throws -> CommonPaginationResponse<[FolderListResponse]> {
        return try await API.Folder.requestRaw(.getFolders(page: page, size: size))
    }
    public func addFolder(folderName: String) async throws -> FolderListResponse {
        return try await API.Folder.request(.addFolder(folderName: folderName))
    }
    public func modifyFolderName(folderId: String, folderName: String) async throws -> EmptyResponse {
        return try await API.Folder.request(.modifyFolderName(folderId: folderId, folderName: folderName))
    }
    public func deleteFolder(folderId: String) async throws -> EmptyResponse {
        return try await API.Folder.request(.deleteFolder(folderId: folderId))
    }
    public func getFolderItemList(folderId: String, page: Int = 0, size: Int = 10) async throws -> CommonPaginationResponse<[WishListResponse]>{
        return try await API.Folder.requestRaw(.getFolderItemList(folderId: folderId, page: page, size: size))
    }
    public func getFolderList() async throws -> [FolderListResponse] {
        return try await API.Folder.request(.getFolderList)
    }
    public func reorderFolders(ids: [Int]) async throws -> EmptyResponse {
        return try await API.Folder.request(.reorderFolders(ids: ids))
    }
}
