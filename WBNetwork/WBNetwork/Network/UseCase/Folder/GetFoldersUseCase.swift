//
//  GetFoldersUseCase.swift
//  WBNetwork
//
//  Created by gomin on 8/18/24.
//

import Foundation

public protocol GetFoldersUseCaseInterface {
    func execute(page: Int, size: Int) async throws -> CommonPaginationResponse<[FolderListResponse]>
}

public class GetFoldersUseCase: GetFoldersUseCaseInterface {
    private let repository: FolderRepositoryInterface
    
    public init(repository: FolderRepositoryInterface = FolderRepository()) {
        self.repository = repository
    }
    
    public func execute(page: Int = 0, size: Int = 10) async throws -> CommonPaginationResponse<[FolderListResponse]> {
        return try await self.repository.getFolders(page: page, size: size)
    }
}
