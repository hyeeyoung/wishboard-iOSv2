//
//  UserAPI.swift
//  WBNetwork
//
//  Created by gomin on 8/24/24.
//

import Foundation
import Moya
import Core

/// 탈퇴 피드백 등록 요청
///
/// `detail` 은 직접 입력이 필요한 사유에서만 보냅니다.
/// 그 외의 사유에 빈 문자열이라도 함께 보내면 400 입니다.
public struct WithdrawalFeedbackRequest {
    /// 탈퇴 사유 목록 조회에서 받은 code
    public let reason: String
    /// 직접 입력 내용. 앞뒤 공백은 서버에서 제거합니다.
    public let detail: String?

    public init(reason: String, detail: String? = nil) {
        self.reason = reason
        self.detail = detail
    }
}

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
    /// 탈퇴 사유 목록 조회
    case getWithdrawalReasons
    /// 탈퇴 피드백 등록
    case postWithdrawalFeedback(request: WithdrawalFeedbackRequest)
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
        case .getWithdrawalReasons:
            return "/withdrawal-reasons"
        case .postWithdrawalFeedback:
            return "/withdrawal-feedback"
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
        case .getWithdrawalReasons:
            return .get
        case .postWithdrawalFeedback:
            return .post
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
        case .postWithdrawalFeedback(let request):
            parameters = ["reason": request.reason]
            // 직접 입력이 필요한 사유에만 담습니다. 빈 문자열이라도 함께 보내면 400 입니다.
            if let detail = request.detail {
                parameters["detail"] = detail
            }
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
    
    func makeMultipartFormData(profileImg: Data?, nickname: String?) -> [Moya.MultipartFormData] {
        var formData: [Moya.MultipartFormData] = []
        
        var requestBody: [String: Any] = [
            "nickname": nickname
        ]

        // JSON 직렬화 → MultipartFormData
        if let jsonData = try? JSONSerialization.data(withJSONObject: requestBody, options: []) {
            let requestPart = MultipartFormData(provider: .data(jsonData), name: "request", mimeType: "application/json")
            formData.append(requestPart)
        }

        // 이미지
        if let image = profileImg {
            let imageData = MultipartFormData(
                provider: .data(image),
                name: "profileImage",
                fileName: "profile.jpeg",
                mimeType: "image/jpeg"
            )
            formData.append(imageData)
        }

        return formData
   }
}
