//
//  HomeViewModel.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation
import Combine
import WBNetwork

final class HomeViewModel {
    
    @Published var items: [WishListResponse] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    func fetchItems() {
        Task {
            do {
                let usecase = GetWishItemsUseCase()
                let data = try await usecase.execute()
                
                DispatchQueue.main.async {
                    self.items = data
                }
            } catch {
                DispatchQueue.main.async {
                    self.items = []
                }
                throw error
            }
        }
    }
}
