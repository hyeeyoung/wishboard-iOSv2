//
//  VersionResponse.swift
//  WBNetwork
//
//  Created by gomin on 3/3/25.
//

import Foundation

public struct VersionResponse: Decodable {
    public let platform: String?
    public let minVersion: String?
    public let recommendedVersion: String?
}
