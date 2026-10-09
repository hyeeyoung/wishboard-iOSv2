//
//  SetFolderThumbnailUseCase.swift
//  WBNetwork
//
//  Created by gomin on 10/9/26.
//

import Foundation

public protocol SetFolderThumbnailUseCaseInterface {
    func execute(folderId: String, itemImageId: Int) async throws -> FolderThumbnailResponse
}

public class SetFolderThumbnailUseCase: SetFolderThumbnailUseCaseInterface {
    private let repository: FolderRepositoryInterface
    
    public init(repository: FolderRepositoryInterface = FolderRepository()) {
        self.repository = repository
    }
    
    public func execute(folderId: String, itemImageId: Int) async throws -> FolderThumbnailResponse {
        return try await self.repository.setFolderThumbnail(folderId: folderId, itemImageId: itemImageId)
    }
}
