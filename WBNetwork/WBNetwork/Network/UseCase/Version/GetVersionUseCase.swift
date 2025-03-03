//
//  GetVersionUseCase.swift
//  WBNetwork
//
//  Created by gomin on 3/3/25.
//

import Foundation

public protocol GetVersionUseCaseInterface {
    func execute() async throws -> VersionResponse
}

public class GetVersionUseCase: GetVersionUseCaseInterface {
    private let repository: VersionRepositoryInterface
    
    public init(repository: VersionRepositoryInterface = VersionRepository()) {
        self.repository = repository
    }
    
    public func execute() async throws -> VersionResponse {
        return try await self.repository.getVersion()
    }
}
