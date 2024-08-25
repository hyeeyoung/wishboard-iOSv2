//
//  AddFolderUseCase.swift
//  WBNetwork
//
//  Created by gomin on 8/25/24.
//

import Foundation

public protocol AddFolderNameUseCaseInterface {
    func execute(folderName: String) async throws -> EmptyResponse
}

public class AddFolderNameUseCase: AddFolderNameUseCaseInterface {
    private let repository: FolderRepositoryInterface
    
    public init(repository: FolderRepositoryInterface = FolderRepository()) {
        self.repository = repository
    }
    
    public func execute(folderName: String) async throws -> EmptyResponse {
        return try await self.repository.addFolder(folderName: folderName)
    }
}
