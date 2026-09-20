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
    /// 페이징으로 새로 불러온 아이템도 선택 상태로 유지하고,
    /// 일괄 삭제 시 scope=ALL 로 보내기 위해 사용합니다.
    private(set) var isSelectAllOn: Bool = false

    /// '전체 선택' 이후 개별 해제한 아이템 id 목록. 일괄 삭제의 excludeItemIds 로 전달됩니다.
    private(set) var excludedItemIds: Set<Int> = []

    var selectedCount: Int { selectedItemIds.count }
    var hasSelection: Bool { !selectedItemIds.isEmpty }

    /// 실제로 삭제될 아이템 개수.
    /// '전체 선택' 상태에서는 아직 불러오지 않은 아이템까지 대상이 되므로,
    /// 화면의 조회 조건에 해당하는 전체 개수에서 해제한 개수를 뺀 값을 사용합니다.
    func deletionTargetCount(filteredTotalCount: Int) -> Int {
        guard isSelectAllOn else { return selectedItemIds.count }
        return max(0, filteredTotalCount - excludedItemIds.count)
    }

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
    /// '전체 선택' 상태에서는 상태를 유지한 채, 해제/재선택한 아이템만 제외 목록에 반영합니다.
    func updateSelection(_ itemIds: Set<Int>) {
        if isSelectAllOn {
            excludedItemIds.formUnion(selectedItemIds.subtracting(itemIds))
            excludedItemIds.subtract(itemIds.subtracting(selectedItemIds))
        }
        apply(itemIds)
    }

    /// 현재 화면에 노출된 모든 아이템을 선택합니다.
    func selectAll(itemIds: [Int]) {
        isSelectAllOn = true
        excludedItemIds = []
        apply(Set(itemIds))
    }

    /// 이미 삭제된 아이템을 선택에서 제외합니다.
    /// 일부만 삭제된 뒤 다시 시도할 때, 지워진 id가 섞여 요청 전체가 실패하지 않도록 합니다.
    func removeFromSelection(_ itemIds: Set<Int>) {
        guard !itemIds.isEmpty else { return }
        excludedItemIds.subtract(itemIds)
        apply(selectedItemIds.subtracting(itemIds))
    }

    func clearSelection() {
        isSelectAllOn = false
        excludedItemIds = []
        apply([])
    }

    /// 페이징으로 아이템이 추가되었을 때 '전체 선택' 상태를 이어서 적용합니다.
    /// 개별 해제한 아이템은 다시 선택되지 않습니다.
    func applySelectAllIfNeeded(itemIds: [Int]) {
        guard isSelectionMode, isSelectAllOn else { return }
        apply(selectedItemIds.union(itemIds).subtracting(excludedItemIds))
    }

    // MARK: - Private

    private func apply(_ itemIds: Set<Int>) {
        guard itemIds != selectedItemIds else { return }
        selectedItemIds = itemIds
    }
}
