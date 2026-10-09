//
//  UpdateItemsStatusBulkUseCase.swift
//  WBNetwork
//
//  Created by gomin on 10/9/26.
//

import Foundation

/// 여러 번에 나눠 호출하던 도중 실패했을 때 발생합니다.
/// 일부 아이템은 이미 처리되었으므로, 호출부에서 목록과 선택 상태를 정리해야 합니다.
public struct BulkItemsPartialFailureError: Error {
    /// 실패하기 전까지 실제로 처리된 아이템 id
    public let processedItemIds: [Int]
    public let underlying: Error

    public init(processedItemIds: [Int], underlying: Error) {
        self.processedItemIds = processedItemIds
        self.underlying = underlying
    }
}

public protocol UpdateItemsStatusBulkUseCaseInterface {
    func execute(request: BulkUpdateItemStatusRequest) async throws -> EmptyResponse
}

public class UpdateItemsStatusBulkUseCase: UpdateItemsStatusBulkUseCaseInterface {
    private let repository: ItemRepositoryInterface

    public init(repository: ItemRepositoryInterface = ItemRepository()) {
        self.repository = repository
    }

    /// 선택한 아이템의 상태를 한 번에 바꿉니다.
    /// itemIds 가 한 요청의 최대 개수를 넘으면 나눠서 순차로 호출하고,
    /// 도중에 실패하면 그때까지 처리된 id를 담은 `BulkItemsPartialFailureError` 를 던집니다.
    public func execute(request: BulkUpdateItemStatusRequest) async throws -> EmptyResponse {
        let requests = request.chunked()
        guard requests.count > 1 else {
            return try await self.repository.updateItemsStatusBulk(request: request)
        }

        var processedItemIds: [Int] = []
        for chunk in requests {
            do {
                _ = try await self.repository.updateItemsStatusBulk(request: chunk)
                processedItemIds.append(contentsOf: chunk.itemIds ?? [])
            } catch {
                throw BulkItemsPartialFailureError(processedItemIds: processedItemIds, underlying: error)
            }
        }
        return EmptyResponse()
    }
}
