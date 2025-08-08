//
//  UserInfoResponse.swift
//  WBNetwork
//
//  Created by gomin on 8/24/24.
//

import Foundation

public struct UserInfoResponse: Decodable {
    public let email: String
    public let profileImgUrl: String?
    public let nickname: String?
    public let pushState: Bool?
    public let id: Int?
  }
