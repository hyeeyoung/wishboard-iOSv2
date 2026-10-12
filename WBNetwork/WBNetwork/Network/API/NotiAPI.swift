//
//  NotiAPI.swift
//  WBNetwork
//
//  Created by gomin on 8/29/24.
//

import Foundation
import Moya
import Core

// TODO: 알림 탭을 다시 v3(GET /v3/noti)로 전환해야 합니다.
// 서버 요청으로 알림 탭을 v2 로 되돌렸습니다. v3 쪽 코드(아래 getNotifications /
// updateReadState, NotificationResponse, GetNotificationsUseCase,
// UpdateReadStateUseCase, NetworkMacro.BaseURLV3)는 다시 켤 수 있도록 남겨 두었습니다.
//
// v2 로 돌아오면서 아래 두 가지가 다시 문제가 됩니다.
//  1) SSE 가 내려주는 안읽음 개수(unread-status)는 v3 기준이라 시스템 알림(공지)이
//     포함되는데, 탭은 v2 라 모집단이 달라 뱃지 개수와 목록 개수가 어긋납니다.
//  2) v2 읽음 처리는 itemId 단위라 시스템 알림을 읽을 수 없어, 뱃지가 내려가지 않습니다.
// 시스템 알림을 쓰기 시작하면 드러나는 문제입니다.
public enum NotiAPI {
    /// 알림 리스트 조회 (v2). 현재 알림 탭이 쓰는 쪽입니다.
    case getNotices
    /// 알림 읽음 처리 (v2). itemId 단위라 시스템 알림은 처리할 수 없습니다.
    case updateState(itemId: String)

    /// 알림 리스트 조회 (v3, 아이템 알림 + 시스템 알림, 페이징)
    ///
    /// SSE 가 내려주는 안읽음 개수와 같은 기준입니다. 지금은 쓰지 않습니다.
    case getNotifications(page: Int, size: Int)
    /// 알림 읽음 처리 (v3). 아이템 알림·시스템 알림 모두 notificationId 로 처리합니다.
    /// 지금은 쓰지 않습니다.
    case updateReadState(notificationId: Int)

    /// 캘린더 알람 조회
    case getCalendar
}

extension NotiAPI: TargetType, AccessTokenAuthorizable {
    public var baseURL: URL {
        switch self {
        case .getNotifications, .updateReadState:
            // v3 전용 경로. 현재 알림 탭은 이 두 케이스를 호출하지 않습니다.
            return URL(string: "\(NetworkMacro.BaseURLV3)/noti")!
        case .getNotices, .updateState, .getCalendar:
            return URL(string: "\(NetworkMacro.BaseURL)/noti")!
        }
    }
    
    public var path: String {
        switch self {
        case .getNotices, .getNotifications:
            return ""
        case .updateState(let itemId):
            return "/\(itemId)/read-state"
        case .updateReadState(let notificationId):
            return "/\(notificationId)/read-state"
        case .getCalendar:
            return "/calendar"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .getNotices, .getNotifications:
            return .get
        case .updateState, .updateReadState:
            return .put
        case .getCalendar:
            return .get
        }
    }

    public var task: Moya.Task {
        var parameters: [String: Any] = [:]

        switch self {
        case .getNotifications(let page, let size):
            // 정렬은 최신순 고정이라 sort 는 보내지 않습니다.
            parameters = ["page": page, "size": size]
        default:
            parameters = [:]
        }
        
        let encoding: ParameterEncoding = self.method == .post ? JSONEncoding.default : URLEncoding.default
        return .requestParameters(parameters: parameters, encoding: encoding)
    }

    public var headers: [String : String]? {
        return NetworkMacro.DeviceInfoHeader
    }
    
    public var authorizationType: Moya.AuthorizationType? {
        return .bearer
    }
    
    public var validationType: ValidationType {
        return .successCodes
    }
}
