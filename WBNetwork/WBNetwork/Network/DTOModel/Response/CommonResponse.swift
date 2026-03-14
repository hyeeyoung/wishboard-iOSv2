//
//  CommonResponse.swift
//  WishboardV2
//
//  Created by gomin on 8/3/24.
//

import Foundation

/// 공통 에러 처리
public struct APIError: Error, Decodable {
    public var status: Int?
    public var success: Bool?
    public var message: String?
    public var code: String?
}

/// 응답구조 통일
/// General 처리
public struct CommonResponse<T: Decodable>: Decodable {
    public var status: Int?
    public var success: Bool?
    public var message: String?
    public var code: String?
    public var data: T?
}

/// 페이징 응답 구조
public struct CommonPaginationResponse<T: Decodable>: Decodable {
    public var status: Int?
    public var success: Bool?
    public var message: String?
    public var code: String?
    public var data: PaginationResponse<T>?
}

public struct PaginationResponse<T: Decodable>: Decodable {
    public let totalPages, totalElements: Int?
    public let first, last: Bool?
    public let size: Int?
    public let content: T?
    public let number: Int?
    public let sort: Sort?
    public let numberOfElements: Int?
    public let pageable: Pageable?
    public let empty: Bool
}

public struct Pageable: Codable {
    public let offset: Int?
    public let sort: Sort?
    public let pageSize: Int?
    public let paged: Bool?
    public let pageNumber: Int?
    public let unpaged: Bool?
}

public struct Sort: Codable {
    public let empty, sorted, unsorted: Bool?
}

public struct EmptyResponse: Codable { }
