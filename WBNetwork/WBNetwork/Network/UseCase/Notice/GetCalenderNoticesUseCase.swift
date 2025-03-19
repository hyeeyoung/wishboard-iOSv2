//
//  GetCalenderNoticesUseCase.swift
//  WBNetwork
//
//  Created by gomin on 3/19/25.
//

import Foundation

public protocol GetCalendarNoticesUseCaseInterface {
    func execute() async throws -> [NoticeResponse]
}

public class GetCalendarNoticesUseCase: GetCalendarNoticesUseCaseInterface {
    private let repository: NoticeRepositoryInterface
    
    public init(repository: NoticeRepositoryInterface = NoticeRepository()) {
        self.repository = repository
    }
    
    public func execute() async throws -> [NoticeResponse] {
        return try await self.repository.getCalendarNotices()
    }
}
