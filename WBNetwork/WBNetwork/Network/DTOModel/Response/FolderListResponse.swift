//
//  FolderListResponse.swift
//  WBNetwork
//
//  Created by gomin on 8/18/24.
//

import Foundation

public struct FolderListResponse: Decodable {
    
    public var folder_id: Int?
    public var folder_name: String?
    public var folder_thumbnail: String?
    public var item_count: Int?
    
    public init(folder_id: Int? = nil, folder_name: String? = nil, folder_thumbnail: String? = nil, item_count: Int? = nil) {
        self.folder_id = folder_id
        self.folder_name = folder_name
        self.folder_thumbnail = folder_thumbnail
        self.item_count = item_count
    }
}
