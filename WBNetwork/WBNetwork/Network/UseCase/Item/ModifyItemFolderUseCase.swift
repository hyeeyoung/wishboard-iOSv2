//
//  ModifyItemFolderUseCase.swift
//  WBNetwork
//
//  Created by gomin on 8/25/24.
//

import Foundation

public protocol ModifyItemFolderUseCaseInterface {
    func execute(itemId: Int, folderId: Int) async throws -> EmptyResponse
}

public class ModifyItemFolderUseCase: ModifyItemFolderUseCaseInterface {
    private let repository: ItemRepositoryInterface
    
    public init(repository: ItemRepositoryInterface = ItemRepository()) {
        self.repository = repository
    }
    
    public func execute(itemId: Int, folderId: Int) async throws -> EmptyResponse {
        return try await self.repository.modifyItemFolder(itemId: itemId, folderId: folderId)
    }
}
