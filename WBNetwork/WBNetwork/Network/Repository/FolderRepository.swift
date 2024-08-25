//
//  FolderRepository.swift
//  WBNetwork
//
//  Created by gomin on 8/18/24.
//

import Foundation

public protocol FolderRepositoryInterface {
    func getFolders() async throws -> [FolderListResponse]
    func addFolder(folderName: String) async throws -> EmptyResponse
    func modifyFolderName(folderId: String, folderName: String) async throws -> EmptyResponse
    func deleteFolder(folderId: String) async throws -> EmptyResponse
    func getFolderItemList(folderId: String) async throws -> [WishListResponse]
    func getFolderList() async throws -> [FolderListResponse]
}

public final class FolderRepository: FolderRepositoryInterface {
    public init() { }
    
    public func getFolders() async throws -> [FolderListResponse] {
        return try await FolderManager.shared.getFolders()
    }
    public func addFolder(folderName: String) async throws -> EmptyResponse {
        return try await FolderManager.shared.addFolder(folderName: folderName)
    }
    public func modifyFolderName(folderId: String, folderName: String) async throws -> EmptyResponse {
        return try await FolderManager.shared.modifyFolderName(folderId: folderId, folderName: folderName)
    }
    public func deleteFolder(folderId: String) async throws -> EmptyResponse {
        return try await FolderManager.shared.deleteFolder(folderId: folderId)
    }
    public func getFolderItemList(folderId: String) async throws -> [WishListResponse] {
        return try await FolderManager.shared.getFolderItemList(folderId: folderId)
    }
    public func getFolderList() async throws -> [FolderListResponse] {
        return try await FolderManager.shared.getFolderList()
    }
}
