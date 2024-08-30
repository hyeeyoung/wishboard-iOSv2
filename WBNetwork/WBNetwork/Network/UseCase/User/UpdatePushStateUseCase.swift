//
//  UpdatePushStateUseCase.swift
//  WBNetwork
//
//  Created by gomin on 8/30/24.
//

import Foundation

public protocol UpdatePushStateUseCaseInterface {
    func execute(state: Bool) async throws -> EmptyResponse
}

public class UpdatePushStateUseCase: UpdatePushStateUseCaseInterface {
    private let repository: UserRepositoryInterface
    
    public init(repository: UserRepositoryInterface = UserRepository()) {
        self.repository = repository
    }
    
    public func execute(state: Bool) async throws -> EmptyResponse {
        return try await self.repository.updatePushState(state: state)
    }
}
