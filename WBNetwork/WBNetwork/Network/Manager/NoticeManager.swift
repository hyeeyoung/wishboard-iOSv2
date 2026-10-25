//
//  NoticeManager.swift
//  WBNetwork
//
//  Created by gomin on 8/29/24.
//

import Foundation

public final class NoticeManager {
    public static let shared = NoticeManager()
    
    // MARK: v2 (지금은 쓰지 않습니다. 되돌릴 때를 위해 남겨 둔 쪽)

    public func getNotices() async throws -> [NoticeResponse] {
        return try await API.Notice.request(.getNotices)
    }

    public func updateState(itemId: String) async throws -> EmptyResponse {
        return try await API.Notice.request(.updateState(itemId: itemId))
    }

    // MARK: v3 (현재 알림 탭이 쓰는 쪽)

    public func getNotifications(page: Int = 0, size: Int = 10) async throws -> CommonPaginationResponse<[NotificationResponse]> {
        return try await API.Notice.requestRaw(.getNotifications(page: page, size: size))
    }
    
    public func updateReadState(notificationId: Int) async throws -> EmptyResponse {
        return try await API.Notice.request(.updateReadState(notificationId: notificationId))
    }
    
    public func getCalendarNotices() async throws -> [NoticeResponse] {
        return try await API.Notice.request(.getCalendar)
    }
}
