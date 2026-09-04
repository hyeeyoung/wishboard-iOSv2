//
//  WebViewTokenResponse.swift
//  WBNetwork
//

import Foundation

public struct WebViewTokenResponse: Decodable {
    public var token: String?
    public var expiresIn: Int?
}
