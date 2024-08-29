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
    private init() { }
    
    /// access token 이 갱신되는 동안 엑세스 되는걸 방지하기 위한 세마포어
    public let sema = DispatchSemaphore(value: 1)

    public func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Swift.Result<URLRequest, Error>) -> Void) {
        print("url: \(String(describing: urlRequest.url))")

        var urlRequest = urlRequest
        
        if let WishBorad_App_Version = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            urlRequest.setValue("iOS v\(WishBorad_App_Version)", forHTTPHeaderField: "X-WishBoard-App-Version")
        }
        
        if let accessToken = UserManager.accessToken {
            urlRequest.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        }
        
        completion(.success(urlRequest))
    }
    
    public func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        // 401 - 유효하지 않은 토큰일 때
        print("\((request.task?.response as? HTTPURLResponse)?.statusCode)")
        guard let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 else {
            let desc = error.asAFError?.errorDescription?.description
            let code = error.asAFError?.responseCode
            print("\(desc)")
            
            let err = NSError(domain: desc ?? "", code: code ?? 500)
            completion(.doNotRetryWithError(err))
            
            return
        }
        
        // 로그인 상태가 아닐 때
        if UserManager.accessToken == nil || UserManager.refreshToken == nil {
            NotificationCenter.default.post(name: .ReceivedNetworkError, object: nil)
            return
        }

        // 토큰 갱신시 동시 실행 제한
        sema.wait()
        
        Task {
            do {
                // call Refresh token API
                let usecase = RefreshTokenUseCase(repository: AuthRepository())
                let data = try await usecase.execute()
                
                guard let accessToken = data.token?.accessToken else {
                    sema.signal()
                    completion(.doNotRetryWithError(error))
                    
                    // 토큰 재발급 실패 시 Notification 이벤트 전송
                    NotificationCenter.default.post(name: .ReceivedNetworkError, object: nil)
                    
                    throw error
                }
                
                guard let refreshToken = data.token?.refreshToken else {
                    sema.signal()
                    completion(.doNotRetryWithError(error))
                    
                    // 토큰 재발급 실패 시 Notification 이벤트 전송
                    NotificationCenter.default.post(name: .ReceivedNetworkError, object: nil)
                    
                    throw error
                }
                
                // save tokens from response
                UserManager.accessToken = accessToken
                UserManager.refreshToken = refreshToken
                
                sema.signal()
                
                // retry
                completion(.retry)
                
            } catch {
                print("refresh token failed.")
                UserManager.removeUserData()
                completion(.doNotRetryWithError(error))
                sema.signal()
                // 토큰 재발급 실패 시 Notification 이벤트 전송
                NotificationCenter.default.post(name: .ReceivedNetworkError, object: nil)
                
                throw error
            }
        }
    }
}
