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
    /// 알림 토글 수정
    case updatePushState(state: Bool)
    /// 유저 탈퇴
    case deleteUser
    /// 유저 정보 수정
    case modifyProfile(profileImg: Data?, nickname: String?)
    /// 비밀번호 변경
    case modifyPassword(password: String)
}

extension UserAPI: TargetType, AccessTokenAuthorizable {
    public var baseURL: URL {
        return URL(string: "\(NetworkMacro.BaseURL)/user")!
    }
    
    public var path: String {
        switch self {
        case .getUserInfo:
            return ""
        case .updatePushState(let state):
            let path = state ? "true" : "false"
            return "push-state/\(path)"
        case .deleteUser:
            return ""
        case .modifyProfile:
            return ""
        case .modifyPassword:
            return "/re-passwd"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .getUserInfo:
            return .get
        case.updatePushState:
            return .put
        case .deleteUser:
            return .delete
        case .modifyProfile:
            return .put
        case .modifyPassword:
            return .put
        }
    }

    public var task: Moya.Task {
        var parameters: [String: Any] = [:]
        
        switch self {
        case .getUserInfo:
            parameters = [:]
        case .modifyProfile(let profilImg, let nickname):
            let formData = makeMultipartFormData(profileImg: profilImg, nickname: nickname)
            return .uploadMultipart(formData)
        case .modifyPassword(let password):
            parameters = ["newPassword": password]
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
    
    func makeMultipartFormData(profileImg: Data?, nickname: String?) -> [Moya.MultipartFormData] {
        
        var nameData: MultipartFormData?
        if let nickname = nickname {
            nameData = MultipartFormData(provider: .data(nickname.data(using: String.Encoding.utf8) ?? Data()), name: "nickname")
        }

        let imageData = profileImg ?? Data()
        let imageMultipartFormData = MultipartFormData(provider: .data(imageData), name: "profile_img", fileName: "profile.jpeg", mimeType: "image/jpeg")
       
       var formData: [Moya.MultipartFormData] = [imageMultipartFormData]
       if let nameData = nameData {
           formData.append(nameData)
       }
       
       return formData
   }
}
