//
//  ItemDetailViewModel.swift
//  WishboardV2
//
//  Created by gomin on 8/18/24.
//

import Foundation
import Combine
import WBNetwork

final class ItemDetailViewModel {
    // Published properties to bind with the view
    @Published var item: WishListResponse?

    init(item: WishListResponse) {
        self.item = item
    }
    
}
