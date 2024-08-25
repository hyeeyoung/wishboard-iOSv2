//
//  CartAPI.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation
import Moya
import Core

public enum CartAPI {
    /// 카트에 추가
    case addCart(itemId: Int)
    /// 카트에서 삭제
    case deleteCart(itemId: Int)
}

extension CartAPI: TargetType {
    public var baseURL: URL {
        return URL(string: "\(NetworkMacro.BaseURL)/cart")!
    }
    
    public var path: String {
        switch self {
        case .addCart(let itemId):
            return ""
        case .deleteCart(let itemId):
            return "/\(itemId)"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .addCart:
            return .post
        case .deleteCart:
            return .delete
        }
    }

    public var task: Moya.Task {
        var parameters: [String: Any] = [:]
        
        switch self {
        case .addCart(let itemId):
            parameters = ["item_id": itemId]
        case .deleteCart:
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
