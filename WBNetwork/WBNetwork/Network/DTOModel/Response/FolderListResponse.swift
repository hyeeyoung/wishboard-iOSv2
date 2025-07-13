//
//  FolderListResponse.swift
//  WBNetwork
//
//  Created by gomin on 8/18/24.
//

import Foundation

public struct FolderListResponse: Decodable {
    public var id: Int?
    public var folderName: String?
    public var folderThumbnail: String?
    public var itemCount: Int?
    
    public init(id: Int? = nil, folderName: String? = nil, folderThumbnail: String? = nil, itemCount: Int? = nil) {
        self.id = id
        self.folderName = folderName
        self.folderThumbnail = folderThumbnail
        self.itemCount = itemCount
    }
}
