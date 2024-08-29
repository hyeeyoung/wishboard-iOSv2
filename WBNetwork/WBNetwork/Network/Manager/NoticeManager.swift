//
//  NoticeManager.swift
//  WBNetwork
//
//  Created by gomin on 8/29/24.
//

import Foundation

public final class NoticeManager {
    public static let shared = NoticeManager()
    
    public func getNotices() async throws -> [NoticeResponse] {
        return try await API.Notice.requestRaw(.getNotices)
    }
    
    public func updateState(itemId: String) async throws -> EmptyResponse {
        return try await API.Notice.request(.updateState(itemId: itemId))
    }
}
