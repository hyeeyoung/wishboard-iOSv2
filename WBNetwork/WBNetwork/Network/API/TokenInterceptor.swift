//
//  TokenInterceptor.swift
//  WishboardV2
//
//  Created by gomin on 8/3/24.
//

import Foundation
import Alamofire
import Core

public final class TokenInterceptor: RequestInterceptor {
    
    static let shared = TokenInterceptor()
    
    /// access token 이 갱신되는 동안 엑세스 되는걸 방지하기 위한 세마포어
    public let sema = DispatchSemaphore(value: 1)

    private init() { }

    public func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Swift.Result<URLRequest, Error>) -> Void) {
        completion(.success(urlRequest))
    }
    
    public func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        
        guard let response = request.task?.response as? HTTPURLResponse else {
            completion(.doNotRetryWithError(error))
            return
        }
        
        // 유저 인증상태 에러 분기처리
        if let dataRequest = request as? DataRequest,
           let data = dataRequest.data {
            if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                switch apiError.code {
                case "NOT_FOUND_USER":
                    NotificationCenter.default.post(name: .SignOutAndShowToast,
                                                    object: nil,
                                                    userInfo: ["SnackBarType": SnackBarType.invalidUser])
                    return
                case "LOGOUT_BY_DEVICE_OVERFLOW":
                    NotificationCenter.default.post(name: .SignOutAndShowToast,
                                                    object: nil,
                                                    userInfo: ["SnackBarType": SnackBarType.logoutByDeviceOverflow])
                    return
                default:
                    break
                }
            }
        }
        
        // 401일 때만 토큰 갱신 로직
        if response.statusCode == 401 {
            // 로그인 상태가 아닐 때
            if UserManager.accessToken == nil || UserManager.refreshToken == nil {
                NotificationCenter.default.post(name: .ReceivedNetworkError, object: nil)
                return
            }
            
            DispatchQueue.global().async {
                // 토큰 갱신시 동시 실행 제한
                self.sema.wait()
                
                Task {
                    defer { self.sema.signal() }
                    do {
                        print("401 에러 발생 - 토큰 재발급 수행")
                        guard let accessToken = UserManager.accessToken, let refreshToken = UserManager.refreshToken else {
                            print("기기에 저장된 refreshToken 정보 없음")
                            return
                        }
                        
                        // call Refresh token API
                        let usecase = RefreshTokenUseCase(repository: AuthRepository())
                        let data = try await usecase.execute(accessToken: accessToken, refreshToken: refreshToken)
                        
                        guard let accessToken = data.accessToken else {
                            self.sema.signal()
                            completion(.doNotRetryWithError(error))
                            
                            // 토큰 재발급 실패 시 Notification 이벤트 전송
                            NotificationCenter.default.post(name: .SignOutAndShowToast,
                                                            object: nil,
                                                            userInfo: ["SnackBarType": SnackBarType.refreshTokenFailed])
                            
                            throw error
                        }
                        
                        guard let refreshToken = data.refreshToken else {
                            self.sema.signal()
                            completion(.doNotRetryWithError(error))
                            
                            // 토큰 재발급 실패 시 Notification 이벤트 전송
                            NotificationCenter.default.post(name: .SignOutAndShowToast,
                                                            object: nil,
                                                            userInfo: ["SnackBarType": SnackBarType.refreshTokenFailed])
                            
                            throw error
                        }
                        
                        // save tokens from response
                        UserManager.accessToken = accessToken
                        UserManager.refreshToken = refreshToken
                        
                        // retry
                        completion(.retry)
                        
                    } catch {
                        print("refresh token failed.")
                        UserManager.removeUserData()
                        completion(.doNotRetryWithError(error))
                        self.sema.signal()
                        // 토큰 재발급 실패 시 Notification 이벤트 전송
                        NotificationCenter.default.post(name: .SignOutAndShowToast,
                                                        object: nil,
                                                        userInfo: ["SnackBarType": SnackBarType.refreshTokenFailed])
                        
                        throw error
                    }
                }
            }
        } else {
            completion(.doNotRetryWithError(error))
            return
        }
    }
}
