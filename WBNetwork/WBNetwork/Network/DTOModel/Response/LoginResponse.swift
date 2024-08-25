//
//  LoginResponse.swift
//  WishboardV2
//
//  Created by gomin on 8/12/24.
//

import Foundation

public struct LoginResponse: Decodable {
    public var token: LoginRepsonseTokenData?
    public var tempNickname: String?
}

public struct LoginRepsonseTokenData: Decodable {
    public var accessToken: String?
    public var refreshToken: String?
}
