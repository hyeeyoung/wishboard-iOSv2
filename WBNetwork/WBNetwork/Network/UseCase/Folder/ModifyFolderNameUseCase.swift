//
//  ModifyFolderNameUseCase.swift
//  WBNetwork
//
//  Created by gomin on 8/25/24.
//

import Foundation

public protocol ModifyFolderNameUseCaseInterface {
    func execute(folderId: String, folderName: String) async throws -> EmptyResponse
}

public class ModifyFolderNameUseCase: ModifyFolderNameUseCaseInterface {
    private let repository: FolderRepositoryInterface
    
    public init(repository: FolderRepositoryInterface = FolderRepository()) {
        self.repository = repository
    }
    
    public func execute(folderId: String, folderName: String) async throws -> EmptyResponse {
        return try await self.repository.modifyFolderName(folderId: folderId, folderName: folderName)
    }
}
