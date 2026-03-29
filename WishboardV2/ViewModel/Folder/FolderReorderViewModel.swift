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
    @Published var showRecentSortButton: Bool = true

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

    // 최근 등록순 정렬
    func sortByRecent() {
        folders.sort { ($0.id ?? 0) > ($1.id ?? 0) }
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

        isSaveEnabled = current != originalOrder

        let recent = folders.sorted { ($0.id ?? 0) > ($1.id ?? 0) }
        let recentIds = recent.compactMap { $0.id }

        showRecentSortButton = current != recentIds
    }

    private func saveCompleted() {
        originalOrder = folders.compactMap { $0.id }
        evaluateState()
    }
}
