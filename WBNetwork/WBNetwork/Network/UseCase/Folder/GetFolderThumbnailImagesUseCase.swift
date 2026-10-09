//
//  GetFolderThumbnailImagesUseCase.swift
//  WBNetwork
//
//  Created by gomin on 10/9/26.
//

import Foundation

public protocol GetFolderThumbnailImagesUseCaseInterface {
    func execute(folderId: String, page: Int, size: Int) async throws -> CommonPaginationResponse<[FolderThumbnailImageResponse]>
}

public class GetFolderThumbnailImagesUseCase: GetFolderThumbnailImagesUseCaseInterface {
    private let repository: FolderRepositoryInterface
    
    public init(repository: FolderRepositoryInterface = FolderRepository()) {
        self.repository = repository
    }
    
    public func execute(folderId: String, page: Int = 0, size: Int = 10) async throws -> CommonPaginationResponse<[FolderThumbnailImageResponse]> {
        return try await self.repository.getFolderThumbnailImages(folderId: folderId, page: page, size: size)
    }
}
