//
//  DeleteItemsBulkUseCase.swift
//  WBNetwork
//
//  Created by gomin on 2026/09/20.
//

import Foundation

/// 여러 번에 나눠 호출하던 도중 실패했을 때 발생합니다.
/// 이미 삭제된 아이템이 있으므로, 호출부에서 목록과 선택 상태를 정리해야 합니다.
public struct BulkDeleteItemsError: Error {
    /// 실패하기 전까지 실제로 삭제된 아이템 id
    public let deletedItemIds: [Int]
    public let underlying: Error

    public init(deletedItemIds: [Int], underlying: Error) {
        self.deletedItemIds = deletedItemIds
        self.underlying = underlying
    }
}

public protocol DeleteItemsBulkUseCaseInterface {
    func execute(request: BulkDeleteItemsRequest) async throws -> EmptyResponse
}

public class DeleteItemsBulkUseCase: DeleteItemsBulkUseCaseInterface {
    private let repository: ItemRepositoryInterface

    public init(repository: ItemRepositoryInterface = ItemRepository()) {
        self.repository = repository
    }

    /// 선택한 아이템을 삭제합니다.
    /// itemIds 가 한 요청의 최대 개수를 넘으면 나눠서 순차로 호출하고,
    /// 도중에 실패하면 그때까지 삭제된 id를 담은 `BulkDeleteItemsError` 를 던집니다.
    public func execute(request: BulkDeleteItemsRequest) async throws -> EmptyResponse {
        let requests = request.chunked()
        guard requests.count > 1 else {
            return try await self.repository.deleteItemsBulk(request: request)
        }

        var deletedItemIds: [Int] = []
        for chunk in requests {
            do {
                _ = try await self.repository.deleteItemsBulk(request: chunk)
                deletedItemIds.append(contentsOf: chunk.itemIds ?? [])
            } catch {
                throw BulkDeleteItemsError(deletedItemIds: deletedItemIds, underlying: error)
            }
        }
        return EmptyResponse()
    }
}
