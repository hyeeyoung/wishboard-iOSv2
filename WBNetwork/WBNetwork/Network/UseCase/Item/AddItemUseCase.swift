//
//  AddItemUseCase.swift
//  WBNetwork
//
//  Created by gomin on 9/1/24.
//

import Foundation

public protocol AddItemUseCaseInterface {
    /// 등록된 아이템을 그대로 돌려줍니다. 등록 직후 상세 화면으로 이동할 때 id가 필요합니다.
    func execute(type: AddItemType, item: RequestItemDTO) async throws -> WishListResponse
}

public class AddItemUseCase: AddItemUseCaseInterface {
    private let repository: ItemRepositoryInterface
    
    public init(repository: ItemRepositoryInterface = ItemRepository()) {
        self.repository = repository
    }
    
    public func execute(type: AddItemType, item: RequestItemDTO) async throws -> WishListResponse {
        return try await self.repository.addItem(type: type, item: item)
    }
}
