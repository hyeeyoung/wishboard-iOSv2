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
        return NetworkMacro.AgentHeader
    }
    
    public var authorizationType: Moya.AuthorizationType? {
        return .bearer
    }
    
    public var validationType: ValidationType {
        return .successCodes
    }
}
