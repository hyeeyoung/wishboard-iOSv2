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
    case getFolders(page: Int, size: Int)
    /// 새 폴더 추가
    case addFolder(folderName: String)
    /// 폴더명 수정
    case modifyFolderName(folderId: String, folderName: String)
    /// 폴더 삭제
    case deleteFolder(folderId: String)
    /// 폴더 내 아이템 리스트 조회
    case getFolderItemList(folderId: String, page: Int, size: Int)
    /// 폴더리스트 조회 - 페이징X
    /// 폴더 탭 화면을 제외한 폴더 리스트 조회 시 사용된다.
    case getFolderList
}

extension FolderAPI: TargetType, AccessTokenAuthorizable {
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
        case .getFolderItemList(let folderId, _, _):
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
        case .getFolders(let page, let size):
            parameters = ["page": page, "size": size]
        case .addFolder(let folderName):
            parameters = ["folderName": folderName]
        case .modifyFolderName(_, let folderName):
            parameters = ["folderName": folderName]
        case .getFolderItemList(_, let page, let size):
            parameters = ["page": page, "size": size]
        default:
            parameters = [:]
        }
        
        let encoding: ParameterEncoding = self.method == .post || self.method == .put ? JSONEncoding.default : URLEncoding.default
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
