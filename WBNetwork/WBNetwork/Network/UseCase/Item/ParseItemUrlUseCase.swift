//
//  ParseItemUrlUseCase.swift
//  WBNetwork
//
//  Created by gomin on 8/25/24.
//

import Foundation

public protocol ParseItemUrlUseCaseInterface {
    func execute(link: String) async throws -> ItemParseResponse?
}

public class ParseItemUrlUseCase: ParseItemUrlUseCaseInterface {
    private let repository: ItemRepositoryInterface
    
    public init(repository: ItemRepositoryInterface = ItemRepository()) {
        self.repository = repository
    }
    
    /// - Returns: 서버가 상품 정보를 못 가져온 경우(204) nil
    public func execute(link: String) async throws -> ItemParseResponse? {
        return try await self.repository.parseItemUrl(link: link)
    }
}
