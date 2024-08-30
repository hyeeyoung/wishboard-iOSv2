//
//  AuthAPI.swift
//  WishboardV2
//
//  Created by gomin on 8/3/24.
//


import Foundation
import Moya
import Core

public enum AuthAPI {
    /// 로그인
    case login(email: String, password: String, fcmToken: String)
    /// 회원가입
    case signUp
    /// 토큰 재발급
    case requestRefreshToken
    /// 로그아웃
    case logout
}

extension AuthAPI: TargetType, AccessTokenAuthorizable {
    
    public var baseURL: URL {
        return URL(string: "\(NetworkMacro.BaseURL)/auth")!
    }
    
    public var path: String {
        switch self {
        case .login:
            return "/signin"
        case .signUp:
            return "/signup"
        case .requestRefreshToken:
            return "/refresh"
        case .logout:
            return "/logout"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .login:
            return .post
        case .signUp:
            return .post
        case .requestRefreshToken:
            return .post
        case .logout:
            return .post
        }
    }

    public var task: Moya.Task {
        var parameters: [String: Any] = [:]
        
        switch self {
        case .login(let email, let password, let fcmToken):
            parameters = ["email": email,
                          "password": password,
                          "fcmToken": fcmToken]
        case .requestRefreshToken:
            guard let refreshToken = UserManager.refreshToken else {break}
            parameters = ["refreshToken": refreshToken]
        default:
            parameters = [:]
        }
        
        let encoding: ParameterEncoding = self.method == .post ? JSONEncoding.default : URLEncoding.default
        return .requestParameters(parameters: parameters, encoding: encoding)
    }

    public var headers: [String : String]? {
        return NetworkMacro.AgentHeader
    }
    
    public var authorizationType: Moya.AuthorizationType? {
        switch self {
        case .logout:
            return .bearer
        default:
            return .none
        }
    }
    
    public var validationType: ValidationType {
        return .successCodes
    }
}
