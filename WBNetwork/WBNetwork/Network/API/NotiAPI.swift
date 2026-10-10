//
//  NotiAPI.swift
//  WBNetwork
//
//  Created by gomin on 8/29/24.
//

import Foundation
import Moya
import Core

public enum NotiAPI {
    /// 알림 리스트 조회 (아이템 알림 + 시스템 알림, 페이징)
    ///
    /// SSE 가 내려주는 안읽음 개수와 같은 기준이라 알림 탭은 이쪽을 씁니다.
    case getNotifications(page: Int, size: Int)
    /// 알림 읽음 처리. 아이템 알림·시스템 알림 모두 notificationId 로 처리합니다.
    case updateReadState(notificationId: Int)
    /// 캘린더 알람 조회
    case getCalendar
}

extension NotiAPI: TargetType, AccessTokenAuthorizable {
    public var baseURL: URL {
        switch self {
        case .getNotifications, .updateReadState:
            // 알림 목록·읽음 처리는 v3 입니다.
            return URL(string: "\(NetworkMacro.BaseURLV3)/noti")!
        case .getCalendar:
            return URL(string: "\(NetworkMacro.BaseURL)/noti")!
        }
    }
    
    public var path: String {
        switch self {
        case .getNotifications:
            return ""
        case .updateReadState(let notificationId):
            return "/\(notificationId)/read-state"
        case .getCalendar:
            return "/calendar"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .getNotifications:
            return .get
        case .updateReadState:
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
