//
//  UpdateStateUseCase.swift
//  WBNetwork
//
//  Created by gomin on 8/29/24.
//

import Foundation

public protocol UpdateStateUseCaseInterface {
    func execute(itemId: String) async throws -> EmptyResponse
}

public class UpdateStateUseCase: UpdateStateUseCaseInterface {
    private let repository: NoticeRepositoryInterface
    
    public init(repository: NoticeRepositoryInterface = NoticeRepository()) {
        self.repository = repository
    }
    
    public func execute(itemId: String) async throws -> EmptyResponse {
        return try await self.repository.updateState(itemId: itemId)
    }
}
