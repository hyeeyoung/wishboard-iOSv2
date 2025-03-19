//
//  NoticeRepository.swift
//  WBNetwork
//
//  Created by gomin on 8/29/24.
//

import Foundation

public protocol NoticeRepositoryInterface {
    func getNotices() async throws -> [NoticeResponse]
    func updateState(itemId: String) async throws -> EmptyResponse
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
    public func getCalendarNotices() async throws -> [NoticeResponse] {
        return try await NoticeManager.shared.getCalendarNotices()
    }
}
