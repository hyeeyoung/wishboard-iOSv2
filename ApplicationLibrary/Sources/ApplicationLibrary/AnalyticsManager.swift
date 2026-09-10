//
//  AnalyticsManager.swift
//  ApplicationLibrary
//
//  Firebase Analytics 이벤트 로깅 래퍼.
//  - 이벤트/파라미터 이름 오타 방지를 위해 enum 기반으로 관리한다.
//  - 새 이벤트 추가는 반드시 `AnalyticsEvent`에 케이스를 먼저 정의한 뒤 호출한다.
//

import Foundation
import FirebaseAnalytics

// MARK: - Event 정의

public enum AnalyticsEvent {
    // Screen
    case screenView(name: ScreenName)

    // Auth
    case loginSucceeded(provider: AuthProvider)
    case signupSucceeded(provider: AuthProvider)
    case withdraw

    // Item
    case itemAdded(source: ItemSource)
    case itemDeleted
    case itemMarkedAsOwned      // 소장템으로 바꾸기

    // Folder
    case folderCreated

    // My Page
    case profileEdited

    // Share Extension
    case shareExtensionOpened  // 공유시트에서 위시보드 선택되어 확장뷰가 뜬 순간

    var name: String {
        switch self {
        case .screenView:           return AnalyticsEventScreenView
        case .loginSucceeded:       return "login_succeeded"
        case .signupSucceeded:      return "signup_succeeded"
        case .withdraw:             return "withdraw"
        case .shareExtensionOpened: return "share_extension_opened"
        case .itemAdded:            return "item_added"
        case .itemDeleted:          return "item_deleted"
        case .itemMarkedAsOwned:    return "item_marked_as_owned"
        case .folderCreated:        return "folder_created"
        case .profileEdited:        return "profile_edited"
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case .screenView(let screen):
            return [AnalyticsParameterScreenName: screen.rawValue,
                    AnalyticsParameterScreenClass: screen.rawValue]
        case .loginSucceeded(let p), .signupSucceeded(let p):
            return ["provider": p.rawValue]
        case .itemAdded(let source):
            return ["source": source.rawValue]
        case .withdraw,
             .itemDeleted,
             .itemMarkedAsOwned,
             .folderCreated,
             .profileEdited,
             .shareExtensionOpened:
            return nil
        }
    }
}

// MARK: - Supporting Types

public enum AuthProvider: String {
    case email
    case apple
    case kakao
    case google
}

public enum ItemSource: String {
    case manual                             // 앱 내 수동 등록
    case shareExtension = "share_extension" // 공유 확장에서 등록
    case linkParsing = "link_parsing"       // 링크 붙여넣기로 자동 파싱 등록
}

public enum ScreenName: String {
    case notification   // 알림 화면
    case calendar       // 캘린더 화면
}

// MARK: - Manager

public final class AnalyticsManager {
    public static let shared = AnalyticsManager()
    private init() {}

    // 이벤트 로깅
    public func log(_ event: AnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.parameters)
    }

    // 유저 식별 (로그인 성공 시 서버 user id 세팅, 로그아웃/탈퇴 시 nil)
    public func setUserID(_ id: String?) {
        Analytics.setUserID(id)
    }
}
