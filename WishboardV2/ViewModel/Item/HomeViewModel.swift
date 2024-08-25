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
                let usecase = GetWishItemsUseCase(repository: ItemRepository())
                let data = try await usecase.execute()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.items = data
                }
            } catch {
                throw error
            }
        }
    }
    
    func toggleCartState(for item: WishListResponse) {
        guard let itemId = item.item_id else {return}
        
        Task {
            do {
                if let cartState = item.cart_state {
                    if cartState == 0 {
                        let usecase = AddCartUseCase(repository: CartRepository())
                        _ = try await usecase.execute(itemId: itemId)
                    } else if cartState == 1 {
                        let usecase = DeleteCartUseCase(repository: CartRepository())
                        _ = try await usecase.execute(itemId: itemId)
                    }
                }
                
                // 서버 응답 후 상태를 업데이트해야 합니다.
                self.updateCartStateUI(for: item)
                
            } catch {
                throw error
            }
        }
    }
    
    private func updateCartStateUI(for item: WishListResponse) {
        if let index = items.firstIndex(where: { $0.item_id == item.item_id }) {
            if items[index].cart_state == 0 {
                items[index].cart_state = 1
            } else if items[index].cart_state == 1 {
                items[index].cart_state = 0
            }
        }
    }
}
