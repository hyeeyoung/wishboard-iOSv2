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

    // 초기 데이터
    func configure(with folders: [FolderListResponse]) {
        self.folders = folders
        self.originalOrder = folders.compactMap { $0.id }
        evaluateState()
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

    // 저장용 순서
    func folderIds() -> [Int] {
        folders.compactMap { $0.id }
    }

    private func evaluateState() {
        let current = folders.compactMap { $0.id }

        isSaveEnabled = current != originalOrder

        let recent = folders.sorted { ($0.id ?? 0) > ($1.id ?? 0) }
        let recentIds = recent.compactMap { $0.id }

        showRecentSortButton = current != recentIds
    }

    func saveCompleted() {
        originalOrder = folders.compactMap { $0.id }
        evaluateState()
    }
}
