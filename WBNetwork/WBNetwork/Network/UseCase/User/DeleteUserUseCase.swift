//
//  DeleteUserUseCase.swift
//  WBNetwork
//
//  Created by gomin on 8/31/24.
//

import Foundation

public protocol DeleteUserUseCaseInterface {
    func execute() async throws -> EmptyResponse
}

public class DeleteUserUseCase: DeleteUserUseCaseInterface {
    private let repository: UserRepositoryInterface
    
    public init(repository: UserRepositoryInterface = UserRepository()) {
        self.repository = repository
    }
    
    public func execute() async throws -> EmptyResponse {
        return try await self.repository.deleteUser()
    }
}
