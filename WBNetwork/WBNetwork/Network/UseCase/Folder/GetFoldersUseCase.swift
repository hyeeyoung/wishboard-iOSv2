//
//  GetFoldersUseCase.swift
//  WBNetwork
//
//  Created by gomin on 8/18/24.
//

import Foundation

public protocol GetFoldersUseCaseInterface {
    func execute() async throws -> [FolderListResponse]
}

public class GetFoldersUseCase: GetFoldersUseCaseInterface {
    private let repository: FolderRepositoryInterface
    
    public init(repository: FolderRepositoryInterface = FolderRepository()) {
        self.repository = repository
    }
    
    public func execute() async throws -> [FolderListResponse] {
        return try await self.repository.getFolders()
    }
}
