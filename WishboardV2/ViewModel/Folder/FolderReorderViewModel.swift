//
//  FolderReorderViewModel.swift
//  WishboardV2
//
//  Created by gomin on 3/14/26.
//

import Foundation
import Combine
import WBNetwork

final class FolderReorderViewModel {

    @Published var folders: [FolderListResponse] = []
    @Published var isSaveEnabled: Bool = false
    @Published var showRestoreButton: Bool = true

    private var originalOrder: [Int] = []
    
    /// 폴더 가져오기 (초기 데이터)
    func fetchFolders() {
        Task {
            do {
                let usecase = GetFolderListUseCase()
                let response = try await usecase.execute()
                
                self.folders = response
                self.originalOrder = folders.compactMap { $0.id }
                evaluateState()
            } catch {
                folders = []
                throw error
            }
        }
    }

    // drag reorder
    func moveItem(from: Int, to: Int) {
        let item = folders.remove(at: from)
        folders.insert(item, at: to)

        evaluateState()
    }
    
    // 폴더 재정렬
    func updateFolderOrders() async throws {
        do {
            let repo = FolderRepository()
            let updateFolderOrdersUseCase = ReorderFoldersUseCase(repository: repo)
            
            let ids = folders.compactMap { $0.id }
            _ = try await updateFolderOrdersUseCase.execute(ids: ids)
            
            self.saveCompleted()
            
        } catch {
            throw error
        }
    }
    
    private func evaluateState() {
        let current = folders.compactMap { $0.id }

        // 저장 버튼
        isSaveEnabled = current != originalOrder

        // 되돌리기 버튼
        showRestoreButton = current != originalOrder
    }
    
    func restoreOriginalOrder() {
        guard !originalOrder.isEmpty else { return }

        let idToFolder: [Int: FolderListResponse] = Dictionary(
            uniqueKeysWithValues: folders.compactMap {
                guard let id = $0.id else { return nil }
                return (id, $0)
            }
        )

        folders = originalOrder.compactMap { idToFolder[$0] }

        evaluateState()
    }

    private func saveCompleted() {
        originalOrder = folders.compactMap { $0.id }
        evaluateState()
    }
}
