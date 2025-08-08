//
//  ItemParseResponse.swift
//  WBNetwork
//
//  Created by gomin on 7/19/25.
//

import Foundation

public struct ItemParseResponse: Decodable {
    public var itemName: String?
    public var itemImageUrl: String?
    public var itemPrice: String?
}
