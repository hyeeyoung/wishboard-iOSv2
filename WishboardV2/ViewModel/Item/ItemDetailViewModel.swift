//
//  ItemDetailViewModel.swift
//  WishboardV2
//
//  Created by gomin on 8/18/24.
//

import Foundation
import Combine
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
