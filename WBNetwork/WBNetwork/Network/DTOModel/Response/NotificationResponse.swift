//
//  NotificationResponse.swift
//  WBNetwork
//
//  Created by gomin on 10/10/26.
//

import Foundation

/// 알림 종류. 종류에 따라 채워지는 필드가 다릅니다.
public enum NotificationCategory: String {
    /// 아이템 알림. item* 필드를 씁니다.
    case item = "ITEM"
    /// 시스템 알림(공지 등). title·body 를 씁니다.
    case system = "SYSTEM"
}

/// v3 알림 목록(`GET /v3/noti`)의 한 건.
///
/// 아이템 알림과 시스템 알림이 한 목록에 섞여 내려오고,
/// `category` 에 해당하지 않는 필드는 null 로 옵니다.
public struct NotificationResponse: Decodable {

    /// 읽음 처리의 키. 아이템 id 가 아닙니다.
    public let notificationId: Int?
    /// 서버가 보내는 그대로의 값. 모르는 값이 와도 깨지지 않도록 문자열로 받습니다.
    public let category: String?
    /// 알림 시각. 두 종류 모두 이 필드를 씁니다. (ISO8601)
    public let notificationDate: String?
    public let readState: Bool?

    // MARK: ITEM
    public let itemId: Int?
    public let itemImages: [ItemImageResponse]?
    public let itemName: String?
    public let itemUrl: String?
    public let itemNotificationType: String?

    // MARK: SYSTEM
    public let title: String?
    public let body: String?

    public var notificationCategory: NotificationCategory {
        NotificationCategory(rawValue: category ?? "") ?? .item
    }

    /// 목록에 보여 줄 시각
    public var displayDate: String {
        notificationDate ?? ""
    }
}
