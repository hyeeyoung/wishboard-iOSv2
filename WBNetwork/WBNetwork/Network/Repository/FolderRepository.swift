//
//  FolderRepository.swift
//  WBNetwork
//
//  Created by gomin on 8/18/24.
//

import Foundation

public protocol FolderRepositoryInterface {
    func getFolders(page: Int, size: Int) async throws -> CommonPaginationResponse<[FolderListResponse]>
    func addFolder(folderName: String) async throws -> FolderListResponse
    func modifyFolderName(folderId: String, folderName: String) async throws -> EmptyResponse
    func deleteFolder(folderId: String) async throws -> EmptyResponse
    func getFolderItemList(folderId: String, page: Int, size: Int) async throws -> CommonPaginationResponse<[WishListResponse]>
    func getFolderList() async throws -> [FolderListResponse]
}

public final class FolderRepository: FolderRepositoryInterface {
    public init() { }
    
    public func getFolders(page: Int = 0, size: Int = 10) async throws -> CommonPaginationResponse<[FolderListResponse]> {
        return try await FolderManager.shared.getFolders(page: page, size: size)
    }
    public func addFolder(folderName: String) async throws -> FolderListResponse {
        return try await FolderManager.shared.addFolder(folderName: folderName)
    }
    public func modifyFolderName(folderId: String, folderName: String) async throws -> EmptyResponse {
        return try await FolderManager.shared.modifyFolderName(folderId: folderId, folderName: folderName)
    }
    public func deleteFolder(folderId: String) async throws -> EmptyResponse {
        return try await FolderManager.shared.deleteFolder(folderId: folderId)
    }
    public func getFolderItemList(folderId: String, page: Int = 0, size: Int = 10) async throws -> CommonPaginationResponse<[WishListResponse]> {
        return try await FolderManager.shared.getFolderItemList(folderId: folderId, page: page, size: size)
    }
    public func getFolderList() async throws -> [FolderListResponse] {
        return try await FolderManager.shared.getFolderList()
    }
}
