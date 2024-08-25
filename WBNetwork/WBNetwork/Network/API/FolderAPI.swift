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
    /// 새 폴더 추가
    case addFolder(folderName: String)
    /// 폴더명 수정
    case modifyFolderName(folderId: String, folderName: String)
    /// 폴더 삭제
    case deleteFolder(folderId: String)
    /// 폴더 내 아이템 리스트 조회
    case getFolderItemList(folderId: String)
    /// 폴더리스트 조회 - 아이템 디테일
    case getFolderList
}

extension FolderAPI: TargetType {
    public var baseURL: URL {
        return URL(string: "\(NetworkMacro.BaseURL)/folder")!
    }
    
    public var path: String {
        switch self {
        case .getFolders:
            return ""
        case .addFolder:
            return ""
        case .modifyFolderName(let folderId, _):
            return "/\(folderId)"
        case .deleteFolder(let folderId):
            return "/\(folderId)"
        case .getFolderItemList(let folderId):
            return "/item/\(folderId)"
        case .getFolderList:
            return "/list"
            
        }
    }

    public var method: Moya.Method {
        switch self {
        case .getFolders:
            return .get
        case .addFolder:
            return .post
        case .modifyFolderName:
            return .put
        case .deleteFolder:
            return .delete
        case .getFolderItemList:
            return .get
        case .getFolderList:
            return .get
        }
    }

    public var task: Moya.Task {
        var parameters: [String: Any] = [:]
        
        switch self {
        case .addFolder(let folderName):
            parameters = ["folder_name": folderName]
        case .modifyFolderName(_, let folderName):
            parameters = ["folder_name": folderName]
        default:
            parameters = [:]
        }
        
        let encoding: ParameterEncoding = self.method == .post || self.method == .put ? JSONEncoding.default : URLEncoding.default
        return .requestParameters(parameters: parameters, encoding: encoding)
    }

    public var headers: [String : String]? {
        return NetworkMacro.AgentHeader
    }
    
    public var validationType: ValidationType {
        return .successCodes
    }
}
