//
//  ErrorPlugin.swift
//  WishboardV2
//
//  Created by gomin on 8/3/24.
//

import Foundation
import Moya
import Alamofire


public class ErrorPlugin: PluginType {
    var lastNetworkError: AFError? // 이전에 발생한 네트워크 에러를 저장할 변수
    
    public func didReceive(_ result: Swift.Result<Response, MoyaError>, target: TargetType) {
        switch result {
        case .failure(let error):
            if let code = error.response?.statusCode {
                switch code {
                case 500:
//                    ErrorAlertManager.shared.showAlert(.serverError)
                    break
                case 400:
//                    ErrorAlertManager.shared.showAlert(.on400Error)
                    break
                default:
//                    ErrorAlertManager.shared.showAlert(.moyaError(error))
                    break
                }
            } else {
//                ErrorAlertManager.shared.showAlert(.moyaError(error))
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
//                    ErrorAlertManager.shared.showAlert(.networkError)
                    return
                case .requestRetryFailed(_, _):
//                    ErrorAlertManager.shared.showAlert(.networkError)
                    break
                default:
//                    ErrorAlertManager.shared.showAlert(.defaultError(afError))
                    break
                }
            }
        default:
            break
        }
    }
    
    public func on400Error(_ error: MoyaError) {
        switch error {
        case .underlying(_, let response):
            if let responseData = response?.data {
                do {
                    
                } catch {
                    print("Error decoding error response: \(error)")
                }
            }
        default:
            break
        }
    }
    
}
