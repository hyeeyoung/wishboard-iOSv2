//
//  GetFolderItemListUseCase.swift
//  WBNetwork
//
//  Created by gomin on 8/25/24.
//

import Foundation

public protocol GetFolderItemListUseCaseInterface {
    func execute(folderId: String) async throws -> [WishListResponse]
}

public class GetFolderItemListUseCase: GetFolderItemListUseCaseInterface {
    private let repository: FolderRepositoryInterface
    
    public init(repository: FolderRepositoryInterface = FolderRepository()) {
        self.repository = repository
    }
    
    public func execute(folderId: String) async throws -> [WishListResponse] {
        return try await self.repository.getFolderItemList(folderId: folderId)
    }
}
