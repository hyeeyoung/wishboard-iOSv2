//
//  VersionAPI.swift
//  WBNetwork
//
//  Created by gomin on 3/3/25.
//


import Foundation
import Moya
import Core

public enum VersionAPI {
    /// 버전 체크
    case getVersion
}

extension VersionAPI: TargetType {
    public var baseURL: URL {
        return URL(string: "\(NetworkMacro.BaseURL)/version/check")!
    }
    
    public var path: String {
        switch self {
        case .getVersion:
            return ""
        }
    }

    public var method: Moya.Method {
        switch self {
        case .getVersion:
            return .get
        }
    }

    public var task: Moya.Task {
        var parameters: [String: Any] = [:]
        switch self {
        case .getVersion:
            parameters = ["osType": "iOS"]
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
