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
    case signUp(email: String, password: String, fcmToken: String)
    /// 토큰 재발급
    case requestRefreshToken(token: String)
    /// 로그아웃
    case logout
    /// 이메일로 로그인하기 전 인증코드 전송
    case emailLogin(email: String)
    /// 회원가입 > 이메일 검증
    case registerEmail(email: String)
    /// 이메일로 로그인
    case loginWithoutPassword(verify: Bool, email: String, fcmToken: String)
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
        case .emailLogin:
            return "/password-mail"
        case .registerEmail:
            return "/check-email"
        case .loginWithoutPassword:
            return "/re-signin"
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
        case .emailLogin:
            return .post
        case .registerEmail:
            return .post
        case .loginWithoutPassword:
            return .post
        }
    }

    public var task: Moya.Task {
        var parameters: [String: Any] = [:]
        
        switch self {
        case .login(let email, let password, let fcmToken),
                .signUp(let email, let password, let fcmToken):
            parameters = ["email": email,
                          "password": password,
                          "fcmToken": fcmToken]
        case .requestRefreshToken(let token):
            parameters = ["refreshToken": token]
        case .emailLogin(let email), .registerEmail(let email):
            parameters = ["email": email]
        case .loginWithoutPassword(let verify, let email, let fcmToken):
            parameters = ["verify": verify,
                          "email": email,
                          "fcmToken": fcmToken]
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
