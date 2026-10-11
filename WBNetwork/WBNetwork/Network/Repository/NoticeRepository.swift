//
//  NoticeRepository.swift
//  WBNetwork
//
//  Created by gomin on 8/29/24.
//

import Foundation

public protocol NoticeRepositoryInterface {
    func getNotifications(page: Int, size: Int) async throws -> CommonPaginationResponse<[NotificationResponse]>
    func updateReadState(notificationId: Int) async throws -> EmptyResponse
    func getCalendarNotices() async throws -> [NoticeResponse]
}

public final class NoticeRepository: NoticeRepositoryInterface {
    public init() { }
    
    public func getNotifications(page: Int = 0, size: Int = 10) async throws -> CommonPaginationResponse<[NotificationResponse]> {
        return try await NoticeManager.shared.getNotifications(page: page, size: size)
    }
    public func updateReadState(notificationId: Int) async throws -> EmptyResponse {
        return try await NoticeManager.shared.updateReadState(notificationId: notificationId)
    }
    public func getCalendarNotices() async throws -> [NoticeResponse] {
        return try await NoticeManager.shared.getCalendarNotices()
    }
}
