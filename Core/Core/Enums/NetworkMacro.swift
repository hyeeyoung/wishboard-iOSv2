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
    
    public static var AgentHeader: [String: String] {
        var header = [
            "User-Agent": "wishboard-ios/dev",
            "Content-Type": "application/json"
        ]
        
        if let deviceInfo = UserManager.deviceInfo {
            header["Device-Info"] = deviceInfo
        }
        
        #if DEBUG
        return header
        #else
        return header
        #endif
    }
    
}
