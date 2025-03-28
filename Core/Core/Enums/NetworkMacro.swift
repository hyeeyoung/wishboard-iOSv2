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
        return "http://3.37.20.199/dev"
        #else
        return "http://3.37.20.199"
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
