//
//  NoticeResponse.swift
//  WBNetwork
//
//  Created by gomin on 8/29/24.
//

import Foundation

public struct NoticeResponse: Decodable {
    public let item_id: Int?
    public let item_img_url: String?
    public let item_name: String?
    public let item_url: String?
    public let item_notification_type: String?
    public let item_notification_date: String?
    public let read_state: Int?
}
