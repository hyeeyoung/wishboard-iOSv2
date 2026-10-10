//
//  NotiAPI.swift
//  WBNetwork
//
//  Created by gomin on 8/29/24.
//

import Foundation
import Moya
import Core

// TODO: 알림 탭을 v3(GET /v3/noti)로 전환해야 합니다.
// SSE 가 내려주는 안읽음 개수(unread-status)는 v3 기준이라 시스템 알림(공지)이 포함되는데,
// 지금 탭은 v2라 모집단이 달라 두 가지 문제가 생깁니다.
//  1) 뱃지 개수와 목록 개수가 어긋납니다. (시스템 알림이 목록에 안 보임)
//  2) v2 읽음 처리는 itemId 단위라 시스템 알림을 읽을 수 없어, 뱃지가 내려가지 않습니다.
// v3 는 notificationId 단위(PUT /v3/noti/{notificationId}/read-state)라 둘 다 해결됩니다.
// 시스템 알림을 쓰기 시작하면 드러나는 문제이며, 전환에는 system-notification-spec.md 가 필요합니다.
public enum NotiAPI {
    /// 알림 리스트 조회
    case getNotices
    /// 알림 읽음 처리
    case updateState(itemId: String)
    /// 캘린더 알람 조회
    case getCalendar
}

extension NotiAPI: TargetType, AccessTokenAuthorizable {
    public var baseURL: URL {
        return URL(string: "\(NetworkMacro.BaseURL)/noti")!
    }
    
    public var path: String {
        switch self {
        case .getNotices:
            return ""
        case .updateState(let itemId):
            return "/\(itemId)/read-state"
        case .getCalendar:
            return "/calendar"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .getNotices:
            return .get
        case .updateState:
            return .put
        case .getCalendar:
            return .get
        }
    }

    public var task: Moya.Task {
        var parameters: [String: Any] = [:]
        parameters = [:]
        
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
