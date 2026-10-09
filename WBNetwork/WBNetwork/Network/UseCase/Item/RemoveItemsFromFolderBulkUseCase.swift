//
//  RemoveItemsFromFolderBulkUseCase.swift
//  WBNetwork
//
//  Created by gomin on 10/9/26.
//

import Foundation

public protocol RemoveItemsFromFolderBulkUseCaseInterface {
    func execute(request: BulkRemoveItemsFromFolderRequest) async throws -> EmptyResponse
}

public class RemoveItemsFromFolderBulkUseCase: RemoveItemsFromFolderBulkUseCaseInterface {
    private let repository: ItemRepositoryInterface

    public init(repository: ItemRepositoryInterface = ItemRepository()) {
        self.repository = repository
    }

    /// 선택한 아이템을 폴더에서 한 번에 뺍니다. 아이템 자체는 지워지지 않습니다.
    /// itemIds 가 한 요청의 최대 개수를 넘으면 나눠서 순차로 호출하고,
    /// 도중에 실패하면 그때까지 처리된 id를 담은 `BulkItemsPartialFailureError` 를 던집니다.
    public func execute(request: BulkRemoveItemsFromFolderRequest) async throws -> EmptyResponse {
        let requests = request.chunked()
        guard requests.count > 1 else {
            return try await self.repository.removeItemsFromFolderBulk(request: request)
        }

        var processedItemIds: [Int] = []
        for chunk in requests {
            do {
                _ = try await self.repository.removeItemsFromFolderBulk(request: chunk)
                processedItemIds.append(contentsOf: chunk.itemIds ?? [])
            } catch {
                throw BulkItemsPartialFailureError(processedItemIds: processedItemIds, underlying: error)
            }
        }
        return EmptyResponse()
    }
}
