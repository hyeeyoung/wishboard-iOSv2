//
//  UserAPI.swift
//  WBNetwork
//
//  Created by gomin on 8/24/24.
//

import Foundation
import Moya
import Core

public enum UserAPI {
    /// 유저 정보 조회
    case getUserInfo
}

extension UserAPI: TargetType {
    public var baseURL: URL {
        return URL(string: "\(NetworkMacro.BaseURL)/user")!
    }
    
    public var path: String {
        switch self {
        case .getUserInfo:
            return ""
        }
    }

    public var method: Moya.Method {
        switch self {
        case .getUserInfo:
            return .get
        }
    }

    public var task: Moya.Task {
        var parameters: [String: Any] = [:]
        
        switch self {
        case .getUserInfo:
            parameters = [:]
        default:
            parameters = [:]
        }
        
        let encoding: ParameterEncoding = self.method == .post ? JSONEncoding.default : URLEncoding.default
        return .requestParameters(parameters: parameters, encoding: encoding)
    }

    public var headers: [String : String]? {
        return NetworkMacro.AgentHeader
    }
    
    public var validationType: ValidationType {
        return .successCodes
    }
}
