//
//  DeleteFolderThumbnailUseCase.swift
//  WBNetwork
//
//  Created by gomin on 10/9/26.
//

import Foundation

public protocol DeleteFolderThumbnailUseCaseInterface {
    func execute(folderId: String) async throws -> FolderThumbnailResponse
}

public class DeleteFolderThumbnailUseCase: DeleteFolderThumbnailUseCaseInterface {
    private let repository: FolderRepositoryInterface
    
    public init(repository: FolderRepositoryInterface = FolderRepository()) {
        self.repository = repository
    }
    
    public func execute(folderId: String) async throws -> FolderThumbnailResponse {
        return try await self.repository.deleteFolderThumbnail(folderId: folderId)
    }
}
