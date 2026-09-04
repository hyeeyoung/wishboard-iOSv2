//
//  TokenInterceptor.swift
//  WishboardV2
//
//  Created by gomin on 8/3/24.
//

import Foundation
import Alamofire
import Core
import EchoKit

public final class TokenInterceptor: RequestInterceptor, Echoable {

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
                    completion(.doNotRetry)
                    return
                case "LOGOUT_BY_DEVICE_OVERFLOW":
                    NotificationCenter.default.post(name: .SignOutAndShowToast,
                                                    object: nil,
                                                    userInfo: ["SnackBarType": SnackBarType.logoutByDeviceOverflow])
                    completion(.doNotRetry)
                    return
                case "INVALID_FCM_TOKEN":
                    UserManager.removeUserData()
                    NotificationCenter.default.post(name: .SignOutAndShowToast,
                                                    object: nil,
                                                    userInfo: ["SnackBarType": SnackBarType.invalidFcmToken])
                    completion(.doNotRetry)
                    return
                default:
                    break
                }
            }
        }

        // 401일 때만 토큰 갱신 로직
        if response.statusCode == 401 {
            // 리프레시 토큰 요청 자체가 401이면 → 재귀 호출(데드락) 방지, 바로 로그아웃
            if let url = request.request?.url?.absoluteString, url.contains("/auth/refresh") {
                UserManager.removeUserData()
                NotificationCenter.default.post(name: .SignOutAndShowToast,
                                                object: nil,
                                                userInfo: ["SnackBarType": SnackBarType.refreshTokenFailed])
                completion(.doNotRetry)
                return
            }

            // 로그인 상태가 아닐 때
            if UserManager.accessToken == nil || UserManager.refreshToken == nil {
                NotificationCenter.default.post(name: .ReceivedNetworkError, object: nil)
                completion(.doNotRetry)
                return
            }

            DispatchQueue.global().async { [self] in
                // 토큰 갱신시 동시 실행 제한
                self.sema.wait()

                Task {
                    defer { self.sema.signal() }
                    do {
                        print("401 에러 발생 - 토큰 재발급 수행")
                        guard let accessToken = UserManager.accessToken,
                              let refreshToken = UserManager.refreshToken else {
                            print("기기에 저장된 refreshToken 정보 없음")
                            NotificationCenter.default.post(name: .SignOutAndShowToast,
                                                            object: nil,
                                                            userInfo: ["SnackBarType": SnackBarType.refreshTokenFailed])
                            completion(.doNotRetry)
                            return
                        }

                        // call Refresh token API
                        let usecase = RefreshTokenUseCase(repository: AuthRepository())
                        let data = try await usecase.execute(accessToken: accessToken, refreshToken: refreshToken)

                        guard let newAccessToken = data.accessToken,
                              let newRefreshToken = data.refreshToken else {
                            NotificationCenter.default.post(name: .SignOutAndShowToast,
                                                            object: nil,
                                                            userInfo: ["SnackBarType": SnackBarType.refreshTokenFailed])
                            completion(.doNotRetryWithError(error))
                            return
                        }

                        // save tokens from response
                        UserManager.accessToken = newAccessToken
                        UserManager.refreshToken = newRefreshToken

                        // retry
                        completion(.retry)

                    } catch {
                        print("refresh token failed.")
                        UserManager.removeUserData()
                        NotificationCenter.default.post(name: .SignOutAndShowToast,
                                                        object: nil,
                                                        userInfo: ["SnackBarType": SnackBarType.refreshTokenFailed])
                        completion(.doNotRetryWithError(error))
                    }
                }
            }
        } else {
            completion(.doNotRetryWithError(error))
            return
        }
    }
}
