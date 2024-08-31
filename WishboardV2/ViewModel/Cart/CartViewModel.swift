//
//  CartViewModel.swift
//  WishboardV2
//
//  Created by gomin on 8/28/24.
//

import Foundation
import Combine
import Foundation
import WBNetwork

struct CartItem {
    let id: Int
    let imageUrl: String
    let name: String
    var quantity: Int
    let price: Int
    
    var itemTotalPrice: Int {
        return price * quantity
    }
}

@MainActor
class CartViewModel: ObservableObject {
    @Published var cartItems: [CartItem] = []
    @Published var totalQuantity: Int = 0
    @Published var totalPrice: Int = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
    }
    
    // 장바구니 리스트 조회
    func fetchCartItems() {
        Task {
            do {
                let useCase = GetCartsUseCase()
                let datas = try await useCase.execute()
                
                var items: [CartItem] = []
                for data in datas {
                    if let wishItem = data.wishItem, let item_id = wishItem.item_id, let itemPrice = wishItem.item_price,
                       let cartItemInfo = data.cartItemInfo, let itemCount = cartItemInfo.item_count {
                        let item = CartItem(id: Int(item_id),
                                        imageUrl: wishItem.item_img ?? "",
                                        name: wishItem.item_name ?? "",
                                        quantity: Int(itemCount),
                                        price: Int(itemPrice) ?? 0)
                        items.append(item)
                    }
                }
                self.cartItems = items
                
                updateTotalValues()
            } catch {
                throw error
            }
        }
    }
    
    // 장바구니 수량 증가
    func increaseQuantity(of item: CartItem) {
        if let index = cartItems.firstIndex(where: { $0.id == item.id }) {
            cartItems[index].quantity += 1
            updateTotalValues()
            updateQuantityInServer(item: cartItems[index])
        }
    }
    
    // 장바구니 수량 감소
    func decreaseQuantity(of item: CartItem) {
        if let index = cartItems.firstIndex(where: { $0.id == item.id }) {
            if cartItems[index].quantity > 1 {
                cartItems[index].quantity -= 1
                updateTotalValues()
                updateQuantityInServer(item: cartItems[index])
            }
        }
    }
    
    // 장바구니 아이템 삭제
    func removeItem(_ item: CartItem) {
        cartItems.removeAll { $0.id == item.id }
        updateTotalValues()
        removeItemFromServer(item: item)
    }
    
    // 장바구니 데이터 UI 업데이트 - 개수, 가격
    private func updateTotalValues() {
        totalQuantity = cartItems.reduce(0) { $0 + $1.quantity }
        totalPrice = cartItems.reduce(0) { $0 + $1.itemTotalPrice }
    }
    
    // 장바구니 아이템 수량 변경 API call
    private func updateQuantityInServer(item: CartItem) {
        Task {
            do {
                let usecase = ModifyCartQuantityUseCase()
                _ = try await usecase.execute(itemId: item.id, itemCount: item.quantity)
            } catch {
                throw error
            }
        }
    }
    
    // 장바구니 아이템 삭제 API call
    private func removeItemFromServer(item: CartItem) {
        Task {
            do {
                let usecase = DeleteCartUseCase()
                _ = try await usecase.execute(itemId: item.id)
                
                DispatchQueue.main.async {
                    SnackBar.shared.show(type: .deleteCartItem)
                }
            } catch {
                throw error
            }
        }
    }
}
