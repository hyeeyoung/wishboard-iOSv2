//
//  ItemSelectionViewModel.swift
//  WishboardV2
//
//  Created by gomin on 2026/09/18.
//

import Foundation
import Combine

/// 홈화면 / 폴더 상세 화면의 아이템 다중 선택 상태를 관리합니다.
final class ItemSelectionViewModel {

    /// 다중 선택 모드 여부
    @Published private(set) var isSelectionMode: Bool = false
    /// 선택된 아이템 id 목록
    @Published private(set) var selectedItemIds: Set<Int> = []

    /// '전체 선택' 상태 여부.
    /// 페이징으로 새로 불러온 아이템도 선택 상태로 유지하기 위해 사용합니다.
    private(set) var isSelectAllOn: Bool = false

    var selectedCount: Int { selectedItemIds.count }
    var hasSelection: Bool { !selectedItemIds.isEmpty }

    // MARK: - Selection Mode

    func enterSelectionMode() {
        clearSelection()
        isSelectionMode = true
    }

    func exitSelectionMode() {
        clearSelection()
        isSelectionMode = false
    }

    // MARK: - Selection

    func isSelected(_ itemId: Int) -> Bool {
        selectedItemIds.contains(itemId)
    }

    func toggle(_ itemId: Int) {
        var updated = selectedItemIds
        if updated.contains(itemId) {
            updated.remove(itemId)
        } else {
            updated.insert(itemId)
        }
        updateSelection(updated)
    }

    /// 유저가 직접 선택/해제한 결과를 반영합니다.
    /// '전체 선택' 버튼 외의 경로로 선택이 바뀌면 전체 선택 상태는 해제됩니다.
    func updateSelection(_ itemIds: Set<Int>) {
        isSelectAllOn = false
        apply(itemIds)
    }

    /// 현재 화면에 노출된 모든 아이템을 선택합니다.
    func selectAll(itemIds: [Int]) {
        isSelectAllOn = true
        apply(Set(itemIds))
    }

    func clearSelection() {
        isSelectAllOn = false
        apply([])
    }

    /// 페이징으로 아이템이 추가되었을 때 '전체 선택' 상태를 이어서 적용합니다.
    func applySelectAllIfNeeded(itemIds: [Int]) {
        guard isSelectionMode, isSelectAllOn else { return }
        apply(selectedItemIds.union(itemIds))
    }

    // MARK: - Private

    private func apply(_ itemIds: Set<Int>) {
        guard itemIds != selectedItemIds else { return }
        selectedItemIds = itemIds
    }
}
