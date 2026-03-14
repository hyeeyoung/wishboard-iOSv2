//
//  GetFolderListUseCase.swift
//  WBNetwork
//
//  Created by gomin on 8/25/24.
//

import Foundation

public protocol GetFolderListUseCaseInterface {
    func execute(order: FolderOrder?) async throws -> [FolderListResponse]
}

public class GetFolderListUseCase: GetFolderListUseCaseInterface {
    private let repository: FolderRepositoryInterface
    
    public init(repository: FolderRepositoryInterface = FolderRepository()) {
        self.repository = repository
    }
    
    public func execute(order: FolderOrder? = nil) async throws -> [FolderListResponse] {
        return try await self.repository.getFolderList(order: order)
    }
}
