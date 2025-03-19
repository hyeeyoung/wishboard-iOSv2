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
    @Published var folders: [FolderListResponse] = []

    init(item: WishListResponse) {
        self.item = item
    }
    
    // 아이템 상세 데이터 가져오기
    func fetchItemDetail(id: Int) {
        Task {
            do {
                let usecase = GetItemDetailUseCase()
                let data = try await usecase.execute(id: id)
                
                DispatchQueue.main.async {
                    self.item = data
                }
            } catch {
                throw error
            }
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
    func modifyItemFolder(itemId: Int, folderId: Int) async throws {
        do {
            let usecase = ModifyItemFolderUseCase()
            let _ = try await usecase.execute(itemId: itemId, folderId: folderId)
            
            self.fetchItemDetail(id: itemId)
            self.fetchFolders()
        } catch {
            throw error
        }
    }
    
    // 아이템 삭제
    func deleteItem(id: Int) async throws {
        do {
            let usecase = DeleteItemUseCase()
            let _ = try await usecase.execute(id: id)
            
            DispatchQueue.main.async {
                SnackBar.shared.show(type: .deleteItem)
            }
        } catch {
            throw error
        }
    }
}
