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
