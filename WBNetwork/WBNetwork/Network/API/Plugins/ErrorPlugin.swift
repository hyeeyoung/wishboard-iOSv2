//
//  ErrorPlugin.swift
//  WishboardV2
//
//  Created by gomin on 8/3/24.
//

import Foundation
import Moya
import Alamofire
import Core

public class ErrorPlugin: PluginType {
    var lastNetworkError: AFError? // 이전에 발생한 네트워크 에러를 저장할 변수
    
    public func didReceive(_ result: Swift.Result<Response, MoyaError>, target: TargetType) {
        switch result {
        case .failure(let error):
            if let code = error.response?.statusCode {
                switch code {
                // Internal Server Error
                case 500:
                    NotificationCenter.default.post(name: .ShowSnackBar, object: nil, userInfo: ["SnackBarType": SnackBarType.errorMessage])
                    break
                // No Data
                case 400:
                    break
                // 업데이트 관련
                case 426:
                    break
                // 유저 상태 관련
                case 401:
                    self.on401Error(error)
                    break
                default:
                    break
                }
            } else {
                self.onFail(error, target: target)
            }
        case .success(_):
            break
        }
    }
    
    public func onFail(_ error: MoyaError, target: TargetType) {
        switch error {
        case .underlying(let afError, _):
            // AFError Code
            if let afError = afError as? AFError {
                switch afError {
                case .sessionTaskFailed(_):
                    NotificationCenter.default.post(name: .ShowSnackBar, object: nil, userInfo: ["SnackBarType": SnackBarType.errorMessage])
                    return
                case .requestRetryFailed(_, _):
                    NotificationCenter.default.post(name: .ShowSnackBar, object: nil, userInfo: ["SnackBarType": SnackBarType.errorMessage])
                    break
                default:
                    break
                }
            }
        default:
            break
        }
    }
    
    public func on401Error(_ error: MoyaError) {
        switch error {
        case .underlying(_, let response):
            if let data = response?.data,
               let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                switch apiError.code {
                case "NOT_FOUND_USER":
                    NotificationCenter.default.post(name: .ShowSnackBar,
                                                    object: nil,
                                                    userInfo: ["SnackBarType": SnackBarType.invalidUser])
                case "LOGOUT_BY_DEVICE_OVERFLOW":
                    NotificationCenter.default.post(name: .SignOutAndShowToast,
                                                    object: nil,
                                                    userInfo: ["SnackBarType": SnackBarType.logoutByDeviceOverflow])
                default:
                    break
                }
            }
        default:
            break
        }
    }
    
}
