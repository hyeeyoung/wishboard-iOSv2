//
//  UserInfoResponse.swift
//  WBNetwork
//
//  Created by gomin on 8/24/24.
//

import Foundation

public struct UserInfoResponse: Decodable {
    public let email: String
    public let profile_img_url: String?
    public let nickname: String?
    public let push_state: Int
  }
