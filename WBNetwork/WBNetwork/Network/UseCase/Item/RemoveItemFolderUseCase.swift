//
//  RemoveItemFolderUseCase.swift
//  WBNetwork
//
//  Created by gomin on 10/10/26.
//

import Foundation

public protocol RemoveItemFolderUseCaseInterface {
    func execute(itemId: Int, folderId: Int) async throws -> EmptyResponse
}

public class RemoveItemFolderUseCase: RemoveItemFolderUseCaseInterface {
    private let repository: ItemRepositoryInterface

    public init(repository: ItemRepositoryInterface = ItemRepository()) {
        self.repository = repository
    }

    /// 아이템에 연결된 폴더를 해제합니다. 아이템과 폴더는 지워지지 않습니다.
    public func execute(itemId: Int, folderId: Int) async throws -> EmptyResponse {
        return try await self.repository.removeItemFolder(itemId: itemId, folderId: folderId)
    }
}
