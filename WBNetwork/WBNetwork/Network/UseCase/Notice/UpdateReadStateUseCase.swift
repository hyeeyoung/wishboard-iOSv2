//
//  UpdateReadStateUseCase.swift
//  WBNetwork
//
//  Created by gomin on 8/29/24.
//

import Foundation

public protocol UpdateReadStateUseCaseInterface {
    func execute(notificationId: Int) async throws -> EmptyResponse
}

/// 알림 읽음 처리. 아이템 알림·시스템 알림 모두 notificationId 로 처리합니다.
public class UpdateReadStateUseCase: UpdateReadStateUseCaseInterface {
    private let repository: NoticeRepositoryInterface
    
    public init(repository: NoticeRepositoryInterface = NoticeRepository()) {
        self.repository = repository
    }
    
    public func execute(notificationId: Int) async throws -> EmptyResponse {
        return try await self.repository.updateReadState(notificationId: notificationId)
    }
}
