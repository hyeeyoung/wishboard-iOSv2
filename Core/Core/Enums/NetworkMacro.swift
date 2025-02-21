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
        #elseif REL
        return "http://3.37.20.199"
        #else
        return ""
        #endif
    }
    
    public static var AgentHeader: [String: String] {
        #if DEBUG
        return [
            "User-Agent": "wishboard-ios/dev",
            "Content-Type": "application/json"
        ]
        #elseif REL
        return [
            "User-Agent": "wishboard-ios/prod",
            "Content-Type": "application/json"
        ]
        #else
        return [:]
        #endif
    }
    
}
