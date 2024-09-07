//
//  ModifyPasswordUseCase.swift
//  WBNetwork
//
//  Created by gomin on 9/7/24.
//

import Foundation

public protocol ModifyPasswordUseCaseInterface {
    func execute(password: String) async throws -> EmptyResponse
}

public class ModifyPasswordUseCase: ModifyPasswordUseCaseInterface {
    private let repository: UserRepositoryInterface
    
    public init(repository: UserRepositoryInterface = UserRepository()) {
        self.repository = repository
    }
    
    public func execute(password: String) async throws -> EmptyResponse {
        return try await self.repository.modifyPassword(password: password)
    }
}
