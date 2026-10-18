//
//  AnalyticsManager.swift
//  ApplicationLibrary
//
//  Firebase Analytics 이벤트 로깅 래퍼.
//  - 이벤트/파라미터 이름 오타 방지를 위해 enum 기반으로 관리한다.
//  - 새 이벤트 추가는 반드시 `AnalyticsEvent`에 케이스를 먼저 정의한 뒤 호출한다.
//

import Foundation
import UIKit
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
    case itemsBulkDeleted(source: BulkDeleteSource, scope: BulkDeleteScope, itemCount: Int)  // 아이템 일괄 삭제
    case itemMarkedAsOwned      // 소장템으로 바꾸기
    case itemParsed(source: ItemParseSource)    // 쇼핑몰 링크로 아이템 정보 불러오기 성공
    case itemMemoEdited         // 아이템 상세 화면에서 메모 간단 편집/저장
    case itemLinkOpenFailed(url: String, source: LinkOpenSource)    // 아이템 링크로 쇼핑몰 열기 실패

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
        case .itemsBulkDeleted:     return "items_bulk_deleted"
        case .itemMarkedAsOwned:    return "item_marked_as_owned"
        case .itemParsed:           return "item_parsed"
        case .itemMemoEdited:       return "item_memo_edited"
        case .itemLinkOpenFailed:   return "item_link_open_failed"
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
        case .itemParsed(let source):
            return ["source": source.rawValue]
        case .itemsBulkDeleted(let source, let scope, let itemCount):
            return ["source": source.rawValue,
                    "scope": scope.rawValue,
                    "item_count": itemCount]
        case .itemLinkOpenFailed(let url, let source):
            // 어떤 링크에서 터지는지 알아야 해서 주소를 통째로 보냅니다.
            // 다만 파라미터 값은 100자까지만 담기므로 잘라서 나눠 담습니다.
            var parameters: [String: Any] = [
                "source": source.rawValue,
                "failure": source.failureStage,
                "url_length": url.count,
                "os_version": UIDevice.current.systemVersion
            ]
            for (index, chunk) in url.chunkedForAnalytics().enumerated() {
                parameters["url_\(index + 1)"] = chunk
            }
            return parameters
        case .withdraw,
             .itemDeleted,
             .itemMarkedAsOwned,
             .itemMemoEdited,
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

/// 쇼핑몰 링크로 아이템 정보를 불러온 경로.
/// 등록 경로를 뜻하는 `ItemSource`와는 의미가 달라 따로 둡니다.
public enum ItemParseSource: String {
    case app                                // 앱 내 아이템 등록/수정 화면
    case shareExtension = "share_extension" // 링크 공유로 진입한 확장뷰
}

/// 아이템 링크를 열려다 실패한 화면과 단계
public enum LinkOpenSource: String {
    /// 아이템 상세 화면에서 주소를 URL 로 만들지 못함
    case itemDetailInvalidURL = "item_detail_invalid_url"
    /// 아이템 상세 화면에서 띄운 사파리가 첫 로딩에 실패함
    case itemDetailLoadFailed = "item_detail_load_failed"
    /// 알림 탭에서 주소를 URL 로 만들지 못함
    case notificationInvalidURL = "notification_invalid_url"
    /// 알림 탭에서 띄운 사파리가 첫 로딩에 실패함
    case notificationLoadFailed = "notification_load_failed"

    /// 주소 자체가 잘못된 것인지, 띄운 뒤 로딩이 안 된 것인지
    var failureStage: String {
        switch self {
        case .itemDetailInvalidURL, .notificationInvalidURL:    return "invalid_url"
        case .itemDetailLoadFailed, .notificationLoadFailed:    return "load_failed"
        }
    }
}

/// 아이템 일괄 삭제를 실행한 화면
public enum BulkDeleteSource: String {
    case home                               // 홈화면
    case folderDetail = "folder_detail"     // 폴더 상세 화면
}

/// 아이템 일괄 삭제 범위
public enum BulkDeleteScope: String {
    case all        // '전체 선택'으로 조회 조건 전체를 삭제
    case selected   // 개별로 고른 아이템만 삭제
}

public enum ScreenName: String {
    case notification   // 알림 화면
    case calendar       // 캘린더 화면
}

// MARK: - 긴 값 나눠 담기

private extension String {
    /// Analytics 파라미터 값 하나에 담을 수 있는 글자 수
    static let analyticsParameterValueLimit = 100
    /// 한 이벤트에 나눠 담을 최대 조각 수. (100자 x 4 = 400자)
    static let analyticsChunkLimit = 4

    /// 100자씩 끊어 돌려줍니다. 길면 앞에서부터 4조각까지만 담습니다.
    ///
    /// 잘린 뒷부분은 `url_length` 로 알 수 있습니다.
    func chunkedForAnalytics() -> [String] {
        guard !isEmpty else { return [] }

        var chunks: [String] = []
        var start = startIndex

        while start < endIndex, chunks.count < String.analyticsChunkLimit {
            let end = index(start,
                            offsetBy: String.analyticsParameterValueLimit,
                            limitedBy: endIndex) ?? endIndex
            chunks.append(String(self[start..<end]))
            start = end
        }

        return chunks
    }
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
