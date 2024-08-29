//
//  ParseItemUrlUseCase.swift
//  WBNetwork
//
//  Created by gomin on 8/25/24.
//

import Foundation

public protocol ParseItemUrlUseCaseInterface {
    func execute(link: String) async throws -> WishListResponse
}

public class ParseItemUrlUseCase: ParseItemUrlUseCaseInterface {
    private let repository: ItemRepositoryInterface
    
    public init(repository: ItemRepositoryInterface = ItemRepository()) {
        self.repository = repository
    }
    
    public func execute(link: String) async throws -> WishListResponse {
        return try await self.repository.parseItemUrl(link: link)
    }
}
