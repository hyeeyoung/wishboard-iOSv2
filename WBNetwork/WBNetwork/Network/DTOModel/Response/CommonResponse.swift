//
//  CommonResponse.swift
//  WishboardV2
//
//  Created by gomin on 8/3/24.
//

import Foundation

/// 응답구조 통일
/// General 처리
public struct CommonResponse<T: Decodable>: Decodable {
    public var success: Bool?
    public var message: String?
    public var data: T?
}

public struct EmptyResponse: Codable { }
