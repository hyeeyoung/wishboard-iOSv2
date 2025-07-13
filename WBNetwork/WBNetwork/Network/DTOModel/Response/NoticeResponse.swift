//
//  NoticeResponse.swift
//  WBNetwork
//
//  Created by gomin on 8/29/24.
//

import Foundation

public struct NoticeResponse: Decodable {
    public let id: Int?
    public let itemImages: [ItemImageResponse]?
    public let itemName: String?
    public let itemUrl: String?
    public let itemNotificationType: String?
    public let itemNotificationDate: String?
    public let readState: Bool?
}
