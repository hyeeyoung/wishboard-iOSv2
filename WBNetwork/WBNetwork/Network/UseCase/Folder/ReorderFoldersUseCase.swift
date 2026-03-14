//
//  ReorderFoldersUseCase.swift
//  WBNetwork
//
//  Created by gomin on 3/15/26.
//

import Foundation

public protocol ReorderFoldersUseCaseInterface {
    func execute(ids: [Int]) async throws -> EmptyResponse
}

public class ReorderFoldersUseCase: ReorderFoldersUseCaseInterface {
    private let repository: FolderRepositoryInterface
    
    public init(repository: FolderRepositoryInterface = FolderRepository()) {
        self.repository = repository
    }
    
    public func execute(ids: [Int]) async throws -> EmptyResponse {
        return try await self.repository.reorderFolders(ids: ids)
    }
}
