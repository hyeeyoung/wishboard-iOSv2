//
//  EventStreamModels.swift
//  WBNetwork
//
//  Created by gomin on 10/10/26.
//

import Foundation

/// 서버가 밀어주는 이벤트 종류.
///
/// 종류가 늘어날 수 있어, 모르는 이름은 무시합니다.
enum EventStreamName: String {
    case unreadStatus = "unread-status"
    case banners = "banners"
    case reconnect = "reconnect"
}

/// 안읽은 알림 상태
public struct UnreadStatusEvent: Decodable {
    public let hasUnread: Bool?
    public let unreadCount: Int?
}

/// 서버가 연결을 닫기 직전에 보내는 안내
struct ReconnectEvent: Decodable {
    let reason: String?
}

/// 연결을 닫는 이유. 이유에 따라 재연결 여부가 달라집니다.
enum ReconnectReason: String {
    /// 토큰 만료가 임박. 갱신 후 바로 재연결합니다.
    case tokenExpiring = "TOKEN_EXPIRING"
    /// 서버 종료(배포 등). 잠시 뒤 재연결합니다.
    case serverShutdown = "SERVER_SHUTDOWN"
    /// 같은 기기의 새 연결이나 기기 수 초과로 닫힘. 재연결하지 않습니다.
    case replaced = "REPLACED"
    /// 로그아웃·탈퇴 등. 재연결하지 않습니다.
    case loggedOut = "LOGGED_OUT"

    /// 모르는 이유는 서버 종료처럼 다룹니다.
    init(rawValue: String?) {
        guard let rawValue = rawValue,
              let reason = ReconnectReason(rawValue: rawValue) else {
            self = .serverShutdown
            return
        }
        self = reason
    }

    var shouldReconnect: Bool {
        switch self {
        case .tokenExpiring, .serverShutdown: return true
        case .replaced, .loggedOut:           return false
        }
    }
}

/// 스트림이 열리기 전에 실패한 경우의 응답
struct EventStreamFailure: Error {
    let statusCode: Int
    let code: String?
}
