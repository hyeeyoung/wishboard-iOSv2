//
//  FolderDetailViewController.swift
//  WishboardV2
//
//  Created by gomin on 8/25/24.
//

import Foundation
import UIKit
import SnapKit
import Then
import Combine
import Core
import WBNetwork

final class FolderDetailViewController: UIViewController, ToolBarDelegate {

    private let folderView: FolderDetailView
    private let viewModel: FolderDetailViewModel
    private let selectionViewModel = ItemSelectionViewModel()
    private let folderTitle: String

    /// 다중 선택 모드에서 노출되는 하단바
    private let selectionBottomBar = ItemSelectionBottomBar().then {
        $0.isHidden = true
    }

    private var cancellables = Set<AnyCancellable>()

    init(folderId: String, folderTitle: String) {
        folderView = FolderDetailView(folderTitle: folderTitle)
        viewModel = FolderDetailViewModel(folderId: folderId)
        self.folderTitle = folderTitle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        self.navigationController?.navigationBar.isHidden = true

        self.view.addSubview(folderView)
        folderView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.horizontalEdges.bottom.equalToSuperview()
        }

        setupSelectionBottomBar()

        folderView.configure(with: viewModel, selectionViewModel: selectionViewModel)
        folderView.collectionView.delegate = self
        folderView.toolbar.delegate = self
        folderView.selectionToolBar.delegate = self
        selectionBottomBar.delegate = self
        viewModel.fetchItems(reset: true)

        folderView.refreshAction = { [weak self] in
            self?.refreshItems()
        }

        setupBindings()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.refreshItems()
    }

    func leftNaviItemTap() {
        UIDevice.vibrate()
        navigationController?.popViewController(animated: true)
    }

    func itemSelectNaviItemTap() {
        UIDevice.vibrate()
        enterSelectionMode()
    }

    func refreshItems() {
        viewModel.fetchItems(reset: true)
    }

    // MARK: - Setup

    private func setupSelectionBottomBar() {
        view.addSubview(selectionBottomBar)
        selectionBottomBar.snp.makeConstraints { make in
            make.horizontalEdges.bottom.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-ItemSelectionBottomBar.height)
        }
    }

    private func setupBindings() {
        selectionViewModel.$selectedItemIds
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateSelectionBottomBar()
            }
            .store(in: &cancellables)

        viewModel.$displayedItems
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateSelectionBottomBar()
            }
            .store(in: &cancellables)
    }
}

// MARK: - 아이템 다중 선택

extension FolderDetailViewController {

    private func enterSelectionMode() {
        selectionViewModel.enterSelectionMode()
        folderView.setSelectionMode(true)
        selectionBottomBar.isHidden = false
        updateSelectionBottomBar()
    }

    private func exitSelectionMode() {
        selectionViewModel.exitSelectionMode()
        folderView.setSelectionMode(false)
        selectionBottomBar.isHidden = true
    }

    private func updateSelectionBottomBar() {
        guard selectionViewModel.isSelectionMode else { return }
        selectionBottomBar.configure(
            selectedCount: deletionTargetCount,
            hasItems: !viewModel.displayedItems.isEmpty
        )
    }

    /// 실제로 삭제될 아이템 개수.
    /// 폴더 상세의 전체 개수는 '소장템 제외' 필터가 이미 반영된 값입니다.
    private var deletionTargetCount: Int {
        selectionViewModel.deletionTargetCount(filteredTotalCount: viewModel.totalCount)
    }

    /// 일괄 삭제 요청 생성
    private func makeBulkDeleteRequest() -> BulkDeleteItemsRequest? {
        guard deletionTargetCount > 0 else { return nil }

        // 전체 선택 상태라면 아직 불러오지 않은 아이템도 대상이므로,
        // 화면의 조회 조건(폴더 + 상태 필터)을 그대로 넘기고 개별 해제한 아이템만 제외합니다.
        if selectionViewModel.isSelectAllOn {
            return .all(
                folderId: Int(viewModel.folderId),
                itemStatus: viewModel.isExcludingOwned ? .wish : nil,
                excludeItemIds: Array(selectionViewModel.excludedItemIds)
            )
        }
        return .selected(itemIds: selectionViewModel.selectedItemIds.sorted())
    }

    /// 선택된 아이템 삭제
    private func requestDeleteSelectedItems() {
        guard let request = makeBulkDeleteRequest() else { return }
        let indicator = ItemSelectionFlow.showLoading(on: self)

        Task { @MainActor [weak self] in
            guard let self = self else { return }
            defer { ItemSelectionFlow.hideLoading(indicator) }

            do {
                try await self.viewModel.deleteItems(request: request)

                self.exitSelectionMode()
                self.refreshItems()
                // 홈화면 등 다른 화면의 목록도 갱신되도록 알립니다.
                NotificationCenter.default.post(name: .ItemUpdated, object: nil)
                SnackBar.shared.show(type: .deleteItem)
            } catch let error as BulkDeleteItemsError {
                // 나눠 호출하던 중 실패한 경우. 이미 삭제된 아이템은 선택에서 빼고
                // 목록을 갱신해, 남은 선택 그대로 다시 시도할 수 있게 합니다.
                self.selectionViewModel.removeFromSelection(Set(error.deletedItemIds))
                self.refreshItems()
                // 홈화면 등 다른 화면의 목록도 갱신되도록 알립니다.
                NotificationCenter.default.post(name: .ItemUpdated, object: nil)
            } catch {
                // 실패 토스트는 ErrorPlugin에서 공통 처리합니다.
                // 선택 상태는 그대로 두어 다시 시도할 수 있게 합니다.
            }
        }
    }
}

extension FolderDetailViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard viewModel.displayedItems.indices.contains(indexPath.row) else { return }
        let item = viewModel.displayedItems[indexPath.row]

        // 다중 선택 모드에서는 셀 전체가 선택 토글 영역이 됩니다.
        if selectionViewModel.isSelectionMode {
            guard let itemIdx = item.id else { return }
            selectionViewModel.toggle(itemIdx)
            return
        }

        if let itemIdx = item.id {
            UIDevice.vibrate()
            let detailViewController = ItemDetailViewController(id: itemIdx)
            navigationController?.pushViewController(detailViewController, animated: true)
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        viewModel.loadNextIfNeeded(currentIndex: indexPath.item)
    }
}

extension FolderDetailViewController: ItemSelectionToolBarDelegate {
    func selectionCloseButtonTap() {
        exitSelectionMode()
    }
}

extension FolderDetailViewController: ItemSelectionBottomBarDelegate {
    func selectionBarDidTapSelectAll() {
        selectionViewModel.selectAll(itemIds: folderView.displayedItemIds())
    }

    func selectionBarDidTapDeselectAll() {
        selectionViewModel.clearSelection()
    }

    func selectionBarDidTapDelete() {
        ItemSelectionFlow.presentDeleteAlert(
            on: self,
            selectedCount: deletionTargetCount
        ) { [weak self] in
            self?.requestDeleteSelectedItems()
        }
    }
}
