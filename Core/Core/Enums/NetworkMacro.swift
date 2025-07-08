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
        #if DEBUG
        return [
            "User-Agent": "wishboard-ios/dev",
            "Content-Type": "application/json"
        ]
        #else
        return [
            "User-Agent": "wishboard-ios/prod",
            "Content-Type": "application/json"
        ]
        #endif
    }
    
}
