//
//  API.swift
//  WishboardV2
//
//  Created by gomin on 8/3/24.
//

import Foundation
import Moya
import Alamofire
import Core

public var configNetworktimeout = Double(20)

public final class API {
    
    public static let tokenClosure: (TargetType) -> String = { _ in
        let accessToken: String = UserManager.accessToken ?? ""
        return accessToken
    }
    
    public static let authPlugin = AccessTokenPlugin(tokenClosure: tokenClosure)
//    public static let networkLoggerPlugin = NetworkLoggerPlugin()
    public static let networkLoggerPlugin = NetworkLoggerPlugin(configuration: .init(
        logOptions: [.formatRequestAscURL, .requestHeaders, .requestBody, .successResponseBody, .errorResponseBody]
    ))
    public static let interceptor = TokenInterceptor.shared
    public static let errorPlugin = ErrorPlugin()
    public static let loadingPlugin = LoadingPlugin()
    
    public static var configuration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = configNetworktimeout
        configuration.timeoutIntervalForResource = configNetworktimeout
        return configuration
    }
    
    public static let Auth = WBProvider<AuthAPI>(
        session: Session(configuration: configuration),
        plugins: [errorPlugin, networkLoggerPlugin, authPlugin]
    )
    
    public static let User = WBProvider<UserAPI>(
        session: Session(configuration: configuration, interceptor: interceptor),
        plugins: [errorPlugin, networkLoggerPlugin, authPlugin, loadingPlugin]
    )
    
    public static let Item = WBProvider<ItemAPI>(
        session: Session(configuration: configuration, interceptor: interceptor),
        plugins: [errorPlugin, networkLoggerPlugin, authPlugin, loadingPlugin]
    )
    
    public static let Cart = WBProvider<CartAPI>(
        session: Session(configuration: configuration, interceptor: interceptor),
        plugins: [errorPlugin, networkLoggerPlugin, authPlugin, loadingPlugin]
    )
    
    public static let Folder = WBProvider<FolderAPI>(
        session: Session(configuration: configuration, interceptor: interceptor),
        plugins: [errorPlugin, networkLoggerPlugin, authPlugin, loadingPlugin]
    )
    
    public static let Notice = WBProvider<NotiAPI>(
        session: Session(configuration: configuration, interceptor: interceptor),
        plugins: [errorPlugin, networkLoggerPlugin, authPlugin, loadingPlugin]
    )
    
    public static let Version = WBProvider<VersionAPI>(
        session: Session(configuration: configuration),
        plugins: [errorPlugin, networkLoggerPlugin, loadingPlugin]
    )
}

public class WBProvider<Target: TargetType> {
    public var provider = MoyaProvider<Target>()

    init(session: Session = MoyaProvider<Target>.defaultAlamofireSession(), plugins: [PluginType] = []) {
        self.provider = MoyaProvider<Target>(session: session, plugins: plugins)
    }
    
    /// Server API 호출 시 사용하는 request 메서드
    public func request<T: Decodable>(_ target: Target) async throws -> T {
        logTask(target)
        
        do {
            let response = try await provider.request(target)
            let responseData = try response.get()
            dto_print(data: responseData)
            
            let data = try JSONDecoder().decode(CommonResponse<T>.self, from: response.get())
            
            if let result = data.data {
                print(result)
                return result
            } else if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            } else {
                let decodingError = DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "디코딩 에러"))
                let error = AFError.responseSerializationFailed(reason: .decodingFailed(error: decodingError))
                throw error
            }
        } catch {
            // 실패 응답 출력
            if let moyaError = error as? MoyaError, let response = moyaError.response {
                dto_print(data: response.data, error: error)
            } else {
                dto_print(data: nil, error: error)
            }
            throw error
        }
    }
    
    /// request 메서드 - 페이징이 있는 응답값일 때
    public func requestPaging<T: Decodable>(_ target: Target) async throws -> T {
        logTask(target)
        
        do {
            let response = try await provider.request(target)
            let responseData = try response.get()
            dto_print(data: responseData)
            
            let data = try JSONDecoder().decode(CommonPaginationResponse<T>.self, from: response.get())
            if let result = data.data?.content {
                print(result)
                return result
            } else if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            } else {
                let decodingError = DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "디코딩 에러"))
                let error = AFError.responseSerializationFailed(reason: .decodingFailed(error: decodingError))
                throw error
            }
        } catch {
            // 실패 응답 출력
            if let moyaError = error as? MoyaError, let response = moyaError.response {
                self.handleError(response.data)
                dto_print(data: response.data, error: error)
            } else {
                dto_print(data: nil, error: error)
            }
            throw error
        }
    }
    
    /// request 메서드 - CommonResponse에 감싸져 있지 않는 응답값일 때
    public func requestRaw<T: Decodable>(_ target: Target) async throws -> T {
        logTask(target)
        
        do {
            let response = try await provider.request(target)
            let responseData = try response.get()
            dto_print(data: responseData)
            
            let data = try JSONDecoder().decode(T.self, from: response.get())
            return data
        } catch {
            // 실패 응답 출력
            if let moyaError = error as? MoyaError, let response = moyaError.response {
                self.handleError(response.data)
                dto_print(data: response.data, error: error)
            } else {
                dto_print(data: nil, error: error)
            }
            throw error
        }
    }
    
    /// 공통 에러 핸들링
    private func handleError(_ errorData: Data) {
        if let apiError = try? JSONDecoder().decode(APIError.self, from: errorData) {
            switch apiError.code {
            case "NOT_FOUND_USER":
                NotificationCenter.default.post(name: .ShowSnackBar, object: nil, userInfo: ["SnackBarType": SnackBarType.invalidUser])
            case "LOGOUT_BY_DEVICE_OVERFLOW":
                NotificationCenter.default.post(name: .ShowSnackBar, object: nil, userInfo: ["SnackBarType": SnackBarType.logoutByDeviceOverflow])
            default:
                return
            }
        }
    }
    
    /// 서버 응답값 로그 출력
    private func dto_print(data: Data?, error: Error? = nil) {
        if let error = error {
            print("❌ Request Failed: \(error.localizedDescription)")
        }
        
        guard let data = data else {
            print("⚠️ No Response Data")
            return
        }
        
        // JSON 데이터인지 확인하고 Pretty Print
        if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
           let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            print("📜 Response JSON:\n\(prettyString)")
        } else if let responseString = String(data: data, encoding: .utf8) {
            print("📄 Response String:\n\(responseString)")
        } else {
            print("📂 Response Data (Binary): \(data)")
        }
    }
}

extension MoyaProvider {
    func request(_ target: Target) async -> Result<Data, MoyaError> {
        await withCheckedContinuation { continuation in
            self.request(target) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: .success(response.data))
                case .failure(let error):
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }
}
