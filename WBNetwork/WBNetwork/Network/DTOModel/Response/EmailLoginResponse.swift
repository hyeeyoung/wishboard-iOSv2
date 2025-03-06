//
//  EmailLoginResponse.swift
//  WBNetwork
//
//  Created by gomin on 3/6/25.
//

import Foundation

public struct EmailLoginResponse: Decodable {
    public var verificationCode: String?
}
