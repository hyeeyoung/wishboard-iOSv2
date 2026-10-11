//
//  NetworkMacro.swift
//  Core
//
//  Created by gomin on 8/3/24.
//

import Foundation

public enum NetworkMacro {
    
    public static var BaseURL: String {
        #if DEBUG
        return "http://43.201.137.248/v2"
        #else
        return "http://43.201.137.248/v2"
        #endif
    }
    
    /// v3 API 경로. 알림 목록·읽음 처리처럼 v3 로 넘어간 API 에 씁니다.
    public static var BaseURLV3: String {
        #if DEBUG
        return "http://43.201.137.248/v3"
        #else
        return "http://43.201.137.248/v3"
        #endif
    }
    
    public static var DefaultHeader: [String: String] {
        #if DEBUG
        let userAgentInfo =  "wishboard-ios/dev"
        #else
        let userAgentInfo =  "wishboard-ios/prod"
        #endif
        
        let header = [
            "User-Agent": userAgentInfo,
            "Content-Type": "application/json"
        ]
        return header
    }
    
    public static var DeviceInfoHeader: [String: String] {
        #if DEBUG
        let userAgentInfo =  "wishboard-ios/dev"
        #else
        let userAgentInfo =  "wishboard-ios/prod"
        #endif

        var header = [
            "User-Agent": userAgentInfo,
            "Content-Type": "application/json"
        ]
        
        if let deviceInfo = UserManager.deviceInfo {
            header["Device-Info"] = deviceInfo
        }
        
        return header
    }
    
}
