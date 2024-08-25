//
//  FolderAPI.swift
//  WBNetwork
//
//  Created by gomin on 8/18/24.
//

import Foundation
import Moya
import Core

public enum FolderAPI {
    /// 폴더리스트 조회
    case getFolders
}

extension FolderAPI: TargetType {
    public var baseURL: URL {
        return URL(string: "\(NetworkMacro.BaseURL)/folder")!
    }
    
    public var path: String {
        switch self {
        case .getFolders:
            return ""
        }
    }

    public var method: Moya.Method {
        switch self {
        case .getFolders:
            return .get
        }
    }

    public var task: Moya.Task {
        var parameters: [String: Any] = [:]
        
        switch self {
        case .getFolders:
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
