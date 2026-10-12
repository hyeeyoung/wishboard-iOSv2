//
//  NoticeRepository.swift
//  WBNetwork
//
//  Created by gomin on 8/29/24.
//

import Foundation

public protocol NoticeRepositoryInterface {
    // v2 (현재 알림 탭이 쓰는 쪽)
    func getNotices() async throws -> [NoticeResponse]
    func updateState(itemId: String) async throws -> EmptyResponse
    // v3 (다시 전환할 때를 위해 남겨 둔 쪽)
    func getNotifications(page: Int, size: Int) async throws -> CommonPaginationResponse<[NotificationResponse]>
    func updateReadState(notificationId: Int) async throws -> EmptyResponse
    func getCalendarNotices() async throws -> [NoticeResponse]
}

public final class NoticeRepository: NoticeRepositoryInterface {
    public init() { }
    
    public func getNotices() async throws -> [NoticeResponse] {
        return try await NoticeManager.shared.getNotices()
    }
    public func updateState(itemId: String) async throws -> EmptyResponse {
        return try await NoticeManager.shared.updateState(itemId: itemId)
    }
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
