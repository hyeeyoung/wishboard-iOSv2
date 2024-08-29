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
    public static let networkLoggerPlugin = NetworkLoggerPlugin()
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
        plugins: [errorPlugin, networkLoggerPlugin]
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
}

public class WBProvider<Target: TargetType> {
    public var provider = MoyaProvider<Target>()

    init(session: Session = MoyaProvider<Target>.defaultAlamofireSession(), plugins: [PluginType] = []) {
        self.provider = MoyaProvider<Target>(session: session, plugins: plugins)
    }
    
    /// Server API 호출 시 사용하는 request 메서드
    public func request<T: Decodable>(_ target: Target) async throws -> T {
        print(target.task)
        
        do {
            let response = try await provider.request(target)
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
            throw error
        }
    }
    
    /// request 메서드 - CommonResponse에 감싸져 있지 않는 응답값일 때
    public func requestRaw<T: Decodable>(_ target: Target) async throws -> T {
        print(target.task)
        
        do {
            let response = try await provider.request(target)
            let data = try JSONDecoder().decode(T.self, from: response.get())
            
            print(data)
            return data
        } catch {
            throw error
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
