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
    /// 장바구니 리스트 조회
    case getCarts
    /// 카트에 추가
    case addCart(itemId: Int)
    /// 장바구니 수량 변경
    case modifyCartQuantity(itemId: Int, itemCount: Int)
    /// 카트에서 삭제
    case deleteCart(itemId: Int)
}

extension CartAPI: TargetType, AccessTokenAuthorizable {
    public var baseURL: URL {
        return URL(string: "\(NetworkMacro.BaseURL)/cart")!
    }
    
    public var path: String {
        switch self {
        case .addCart(let itemId):
            return ""
        case .deleteCart(let itemId):
            return "/\(itemId)"
        case .getCarts:
            return ""
        case .modifyCartQuantity(let itemId, _):
            return "/\(itemId)"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .getCarts:
            return .get
        case .addCart:
            return .post
        case .deleteCart:
            return .delete
        case .modifyCartQuantity:
            return .put
        }
    }

    public var task: Moya.Task {
        var parameters: [String: Any] = [:]
        
        switch self {
        case .addCart(let itemId):
            parameters = ["item_id": itemId]
        case .deleteCart:
            parameters = [:]
        case .modifyCartQuantity(_, let itemCount):
            parameters = ["item_count": itemCount]
        default:
            parameters = [:]
        }
        
        let encoding: ParameterEncoding = self.method == .post || self.method == .put ? JSONEncoding.default : URLEncoding.default
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
