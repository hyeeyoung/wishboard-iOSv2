//
//  GetNoticesUseCase.swift
//  WBNetwork
//
//  Created by gomin on 8/29/24.
//

import Foundation

public protocol GetNoticesUseCaseInterface {
    func execute() async throws -> [NoticeResponse]
}

public class GetNoticesUseCase: GetNoticesUseCaseInterface {
    private let repository: NoticeRepositoryInterface
    
    public init(repository: NoticeRepositoryInterface = NoticeRepository()) {
        self.repository = repository
    }
    
    public func execute() async throws -> [NoticeResponse] {
        return try await self.repository.getNotices()
    }
}
