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
        ItemSelectionFlow.presentSelectionActionSheet(on: self) { [weak self] in
            self?.enterSelectionMode()
        }
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
            selectedCount: selectionViewModel.selectedCount,
            hasItems: !viewModel.displayedItems.isEmpty
        )
    }

    /// 선택된 아이템 삭제
    private func requestDeleteSelectedItems() {
        guard selectionViewModel.hasSelection else { return }
        let indicator = ItemSelectionFlow.showLoading(on: self)

        Task { @MainActor [weak self] in
            guard let self = self else { return }
            defer { ItemSelectionFlow.hideLoading(indicator) }

            // TODO: 아이템 다중 삭제 API 연동 시, selectionViewModel.selectedItemIds 를 전달해 이 위치에서 호출합니다.

            self.exitSelectionMode()
            self.refreshItems()
            SnackBar.shared.show(type: .deleteItem)
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
            selectedCount: selectionViewModel.selectedCount
        ) { [weak self] in
            self?.requestDeleteSelectedItems()
        }
    }
}
