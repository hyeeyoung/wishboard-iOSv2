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
    /// 위시아이템 삭제
    case deleteItem(id: Int)
    /// 아이템 디테일 조회
    case getItemDetail(id: Int)
    /// 아이템의 폴더 지정
    case modifyItemFolder(itemId: Int, folderId: Int)
}

extension ItemAPI: TargetType {
    public var baseURL: URL {
        return URL(string: "\(NetworkMacro.BaseURL)/item")!
    }
    
    public var path: String {
        switch self {
        case .getWishItems:
            return ""
        case .deleteItem(let id):
            return "/\(id)"
        case .getItemDetail(let id):
            return "/\(id)"
        case .modifyItemFolder(let itemId, let folderId):
            return "/\(itemId)/folder/\(folderId)"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .getWishItems, .getItemDetail:
            return .get
        case .modifyItemFolder:
            return .put
        case .deleteItem:
            return .delete
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
