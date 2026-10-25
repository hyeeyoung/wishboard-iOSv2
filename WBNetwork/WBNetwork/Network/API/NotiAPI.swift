//
//  NotiAPI.swift
//  WBNetwork
//
//  Created by gomin on 8/29/24.
//

import Foundation
import Moya
import Core

// 알림 탭은 v3(GET /v3/noti)를 씁니다.
//
// v3 를 쓰는 이유는 두 가지입니다.
//  1) SSE 가 내려주는 안읽음 개수(unread-status)가 v3 기준이라, 탭도 v3 여야
//     뱃지 개수와 목록 개수의 모집단이 같습니다.
//  2) v3 읽음 처리는 notificationId 단위라 시스템 알림(공지)도 읽을 수 있습니다.
//     v2 는 itemId 단위여서 시스템 알림을 읽지 못해 뱃지가 내려가지 않습니다.
//
// 3.4.0 에서 시스템 알림을 다루지 않기로 하며 잠시 v2 로 되돌렸던 적이 있습니다.
// v2 쪽 코드(아래 getNotices / updateState, GetNoticesUseCase, UpdateStateUseCase)는
// 그때처럼 다시 돌아갈 수 있도록 남겨 둡니다. 지금은 캘린더만 v2 를 씁니다.
public enum NotiAPI {
    /// 알림 리스트 조회 (v3, 아이템 알림 + 시스템 알림, 페이징)
    ///
    /// SSE 가 내려주는 안읽음 개수와 같은 기준이라 알림 탭은 이쪽을 씁니다.
    case getNotifications(page: Int, size: Int)
    /// 알림 읽음 처리 (v3). 아이템 알림·시스템 알림 모두 notificationId 로 처리합니다.
    case updateReadState(notificationId: Int)

    /// 알림 리스트 조회 (v2). 지금은 쓰지 않습니다.
    case getNotices
    /// 알림 읽음 처리 (v2). itemId 단위라 시스템 알림은 처리할 수 없습니다.
    /// 지금은 쓰지 않습니다.
    case updateState(itemId: String)

    /// 캘린더 알람 조회
    case getCalendar
}

extension NotiAPI: TargetType, AccessTokenAuthorizable {
    public var baseURL: URL {
        switch self {
        case .getNotifications, .updateReadState:
            // 알림 목록·읽음 처리는 v3 입니다.
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
