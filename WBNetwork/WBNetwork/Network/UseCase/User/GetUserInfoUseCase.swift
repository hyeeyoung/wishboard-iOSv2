//
//  GetUserInfoUseCase.swift
//  WBNetwork
//
//  Created by gomin on 8/24/24.
//

import Foundation

public protocol GetUserInfoUseCaseInterface {
    func execute() async throws -> [UserInfoResponse]
}

public class GetUserInfoUseCase: GetUserInfoUseCaseInterface {
    private let repository: UserRepositoryInterface
    
    public init(repository: UserRepositoryInterface = UserRepository()) {
        self.repository = repository
    }
    
    public func execute() async throws -> [UserInfoResponse] {
        return try await self.repository.getUserInfo()
    }
}
