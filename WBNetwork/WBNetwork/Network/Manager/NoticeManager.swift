//
//  NoticeManager.swift
//  WBNetwork
//
//  Created by gomin on 8/29/24.
//

import Foundation

public final class NoticeManager {
    public static let shared = NoticeManager()
    
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
