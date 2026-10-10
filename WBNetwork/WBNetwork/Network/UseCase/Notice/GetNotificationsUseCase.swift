//
//  GetNotificationsUseCase.swift
//  WBNetwork
//
//  Created by gomin on 8/29/24.
//

import Foundation

public protocol GetNotificationsUseCaseInterface {
    func execute(page: Int, size: Int) async throws -> CommonPaginationResponse<[NotificationResponse]>
}

/// 알림 탭 목록 조회. 아이템 알림과 시스템 알림이 함께 내려옵니다.
public class GetNotificationsUseCase: GetNotificationsUseCaseInterface {
    private let repository: NoticeRepositoryInterface
    
    public init(repository: NoticeRepositoryInterface = NoticeRepository()) {
        self.repository = repository
    }
    
    public func execute(page: Int = 0, size: Int = 10) async throws -> CommonPaginationResponse<[NotificationResponse]> {
        return try await self.repository.getNotifications(page: page, size: size)
    }
}
