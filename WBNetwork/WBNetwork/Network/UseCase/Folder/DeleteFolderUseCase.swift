//
//  DeleteFolderUseCase.swift
//  WBNetwork
//
//  Created by gomin on 8/25/24.
//

import Foundation

public protocol DeleteFolderUseCaseInterface {
    func execute(folderId: String) async throws -> EmptyResponse
}

public class DeleteFolderUseCase: DeleteFolderUseCaseInterface {
    private let repository: FolderRepositoryInterface
    
    public init(repository: FolderRepositoryInterface = FolderRepository()) {
        self.repository = repository
    }
    
    public func execute(folderId: String) async throws -> EmptyResponse {
        return try await self.repository.deleteFolder(folderId: folderId)
    }
}
