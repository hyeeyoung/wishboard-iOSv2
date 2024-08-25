//
//  ItemAPI.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation
import Moya
import Core

public enum ItemAPI {
    /// 위시리스트 조회
    case getWishItems
}

extension ItemAPI: TargetType {
    public var baseURL: URL {
        return URL(string: "\(NetworkMacro.BaseURL)/item")!
    }
    
    public var path: String {
        switch self {
        case .getWishItems:
            return ""
        }
    }

    public var method: Moya.Method {
        switch self {
        case .getWishItems:
            return .get
        }
    }

    public var task: Moya.Task {
        var parameters: [String: Any] = [:]
        
        switch self {
        case .getWishItems:
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
