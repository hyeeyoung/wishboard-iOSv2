//
//  ItemDetailViewModel.swift
//  WishboardV2
//
//  Created by gomin on 8/18/24.
//

import Foundation
import Combine
import Core
@preconcurrency import WBNetwork

final class ItemDetailViewModel {
    var itemId: Int?
    // Published properties to bind with the view
    @Published var item: WishListResponse?
    @Published var folders: [FolderListResponse] = []

    init() {
        
    }
    
    // 아이템 상세 데이터 가져오기
    func fetchItemDetail() async throws {
        do {
            guard let itemId = self.itemId else { return }
            let usecase = GetItemDetailUseCase()
            let data = try await usecase.execute(id: itemId)
            
            DispatchQueue.main.async {
                self.item = data
            }
        } catch {
            throw error
        }
    }
    
    // 폴더 데이터 가져오기
    func fetchFolders() {
        Task {
            do {
                let usecase = GetFolderListUseCase()
                let data = try await usecase.execute()
                
                DispatchQueue.main.async {
                    self.folders = data
                }
            } catch {
                throw error
            }
        }
    }
    
    // 아이템의 폴더 지정하기
    func modifyItemFolder(folderId: Int) async throws {
        do {
            guard let itemId = self.itemId else { return }
            let usecase = ModifyItemFolderUseCase()
            let _ = try await usecase.execute(itemId: itemId, folderId: folderId)
            
            try await self.fetchItemDetail()
            self.fetchFolders()
        } catch {
            throw error
        }
    }
    
    /// 메모만 수정
    /// 아이템 수정 API는 전체 필드를 받으므로, 메모를 뺀 나머지는 현재 값을 그대로 다시 보냅니다.
    func updateMemo(_ memo: String) async throws {
        guard let itemId = self.itemId, let item = self.item else { return }

        let originPrice = FormatManager.shared.priceToStr(price: item.itemPrice ?? "0")

        let request = RequestItemDTO(
            folderId: item.folderId,
            photos: nil,
            itemName: item.itemName ?? "",
            itemPrice: Int(originPrice) ?? 0,
            itemURL: item.itemUrl,
            itemMemo: memo,
            itemNotificationType: item.itemNotificationType,
            itemNotificationDate: item.itemNotificationDate?.replacingOccurrences(of: "T", with: " "),
            version: item.version,
            // 이미지는 건드리지 않습니다.
            imageChanged: false
        )

        let usecase = ModifyItemUseCase()
        _ = try await usecase.execute(idx: itemId, item: request)
    }

    // 아이템 삭제
    func deleteItem() async throws {
        do {
            guard let id = self.itemId else { return }
            let usecase = DeleteItemUseCase()
            let _ = try await usecase.execute(id: id)
            
            DispatchQueue.main.async {
                SnackBar.shared.show(type: .deleteItem)
            }
        } catch {
            throw error
        }
    }
    
    // 아이템 상태 변경
    func updateItemStatus(status: ItemStatusType) async throws {
        do {
            guard let itemId = self.itemId else { return }
            
            let usecase = UpdateItemStatusUseCase()
            let _ = try await usecase.execute(idx: itemId, status: status)
            
        } catch {
            throw error
        }
    }
}
