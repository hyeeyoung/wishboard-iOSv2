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
        
        // TODO: 다른 기기에서 탈퇴한 회원일 때: 401에러 + 별도 에러 코드 제공해준다고 함.
        // 그때 아래 코드 추가
        // NotificationCenter.default.post(name: .ReceivedNetworkError, object: nil)
        // 위 코드 줄 추가하면 온보딩 화면으로 이동하고 유저데이터 삭제 처리
        
        guard let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 else {
            let desc = error.asAFError?.errorDescription?.description
            let code = error.asAFError?.responseCode
            print("\(desc)")
            
            let err = NSError(domain: desc ?? "", code: code ?? 500)
            NotificationCenter.default.post(name: .ReceivedNetworkError, object: nil)
            completion(.doNotRetryWithError(err))
            
            return
        }
        
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
                    guard let accessToken = UserManager.accessToken, let refreshToken = UserManager.refreshToken else {
                        print("기기에 저장된 refreshToken 정보 없음")
                        return
                    }
                    
                    // call Refresh token API
                    let usecase = RefreshTokenUseCase(repository: AuthRepository())
                    let data = try await usecase.execute(accessToken: accessToken, refreshToken: refreshToken)
                    
                    guard let accessToken = data.token?.accessToken else {
                        self.sema.signal()
                        completion(.doNotRetryWithError(error))
                        
                        // 토큰 재발급 실패 시 Notification 이벤트 전송
                        NotificationCenter.default.post(name: .ReceivedNetworkError, object: nil)
                        
                        throw error
                    }
                    
                    guard let refreshToken = data.token?.refreshToken else {
                        self.sema.signal()
                        completion(.doNotRetryWithError(error))
                        
                        // 토큰 재발급 실패 시 Notification 이벤트 전송
                        NotificationCenter.default.post(name: .ReceivedNetworkError, object: nil)
                        
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
                    NotificationCenter.default.post(name: .ReceivedNetworkError, object: nil)
                    
                    throw error
                }
            }
        }
    }
}
