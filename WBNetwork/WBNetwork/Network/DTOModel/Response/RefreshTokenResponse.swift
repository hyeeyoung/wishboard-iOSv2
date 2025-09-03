//
//  RefreshTokenResponse.swift
//  WBNetwork
//
//  Created by gomin on 9/3/25.
//

public struct RefreshTokenResponse: Decodable {
    public var accessToken: String?
    public var refreshToken: String?
}
