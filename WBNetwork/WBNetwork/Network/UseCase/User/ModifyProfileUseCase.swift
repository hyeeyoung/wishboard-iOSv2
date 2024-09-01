//
//  ModifyProfileUseCase.swift
//  WBNetwork
//
//  Created by gomin on 9/1/24.
//

import Foundation

public protocol ModifyProfileUseCaseInterface {
    func execute(profileImg: Data?, nickname: String?) async throws -> EmptyResponse
}

public class ModifyProfileUseCase: ModifyProfileUseCaseInterface {
    private let repository: UserRepositoryInterface
    
    public init(repository: UserRepositoryInterface = UserRepository()) {
        self.repository = repository
    }
    
    public func execute(profileImg: Data?, nickname: String?) async throws -> EmptyResponse {
        return try await self.repository.modifyProfile(profileImg: profileImg, nickname: nickname)
    }
}
