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

/// 홈 상단에 붙는 한 줄 배너.
///
/// 노출 대상(OS·버전·기간)은 서버가 이미 걸러서 보냅니다. 앱은 받은 순서 그대로 보여 주고,
/// 로컬에 닫기 기록이 있는 것만 뺍니다.
public struct BannerEvent: Decodable, Equatable {
    public let id: Int
    public let placement: String?
    public let text: String?
    /// `#RRGGBB` 또는 `#AARRGGBB`. 알파가 앞 2자리입니다.
    public let textColor: String?
    public let backgroundColor: String?
    /// 탭 시 동작. 모르는 값은 `none` 으로 다룹니다.
    public let type: String?
    /// `type` 에 쓰이는 값. DEEPLINK 는 URL 이 아닐 수 있습니다.
    public let value: String?
    public let dismissible: Bool?

    public var isHomeTop: Bool {
        placement == BannerPlacement.homeTop.rawValue
    }

    public var action: BannerActionType {
        BannerActionType(rawValue: type)
    }

    public var isDismissible: Bool {
        dismissible ?? false
    }
}

/// 배너 노출 위치. 지금은 홈 상단만 있습니다.
public enum BannerPlacement: String {
    case homeTop = "HOME_TOP"
}

/// 배너를 탭했을 때의 동작
public enum BannerActionType: String {
    /// 앱 내 화면으로 이동. 처리할 수 없는 값이면 아무 동작도 하지 않습니다.
    case deeplink = "DEEPLINK"
    /// 외부 브라우저로 염
    case web = "WEB"
    /// 반응 없음
    case none = "NONE"

    /// 종류가 늘어날 수 있어, 모르는 값은 반응 없음으로 다룹니다.
    public init(rawValue: String?) {
        guard let rawValue = rawValue,
              let type = BannerActionType(rawValue: rawValue) else {
            self = .none
            return
        }
        self = type
    }
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
