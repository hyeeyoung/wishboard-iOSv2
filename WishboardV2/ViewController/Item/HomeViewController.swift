//
//  HomeViewController.swift
//  WishboardV2
//
//  Created by gomin on 8/16/24.
//

import Foundation
import UIKit
import SnapKit
import Then
import Combine
import Core
import WBNetwork
import ApplicationLibrary

final class HomeViewController: UIViewController, ItemDetailDelegate {

    private let homeView = HomeView()
    private let viewModel = HomeViewModel()
    private let selectionViewModel = ItemSelectionViewModel()

    /// 이벤트 영역 > x버튼
    private static let eventBannerDismissedAtKey = "eventBannerDismissedAt"

    private let backgroundDimView = UIView()
    /// 다중 선택 모드에서 탭바 대신 노출되는 하단바
    private let selectionBottomBar = ItemSelectionBottomBar().then {
        $0.isHidden = true
    }

    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        self.navigationController?.navigationBar.isHidden = true

        setupNotifications()
        setupUI()
        setupDelegates()
        setupBackgroundDimView()
        setupSelectionBottomBar()
        setupBottomSheet()
        setupBindings()

        self.refreshItems()

        // 앱 이용방법
        guard let isFirstLogin = UserManager.isFirstLogin else { return }
        if isFirstLogin {
            self.showAppGuideSheet()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 다중 선택 모드에서는 탭바 대신 선택 하단바가 노출됩니다.
        self.tabBarController?.tabBar.isHidden = selectionViewModel.isSelectionMode
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(refreshItems), name: .ItemUpdated, object: nil)
    }

    private func setupUI() {
        view.addSubview(homeView)
        homeView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.bottom.equalToSuperview()
        }
        homeView.configure(with: viewModel, selectionViewModel: selectionViewModel)
        setupEventBanner()
    }

    private func setupEventBanner() {
        if shouldHideEventBanner {
            homeView.hideEventBanner()
            return
        }

        homeView.eventBannerView.onClose = { [weak self] in
            guard let self else { return }

            UserDefaults.standard.set(
                Date(),
                forKey: Self.eventBannerDismissedAtKey
            )

            self.homeView.hideEventBanner()

            // show toast
            SnackBar.shared.show(type: .hideEventBanner)
        }

        homeView.eventBannerView.onTap = { [weak self] in
            guard let self else { return }
            self.presentWishboardWebView()
        }
    }

    private func presentWishboardWebView() {
        let webVC = WishboardWebViewController()
        webVC.modalPresentationStyle = .fullScreen
        present(webVC, animated: true)
    }

    private var shouldHideEventBanner: Bool {
        guard let _ = UserDefaults.standard.object(
            forKey: Self.eventBannerDismissedAtKey
        ) else {
            return false
        }
        return true
    }

    private func setupDelegates() {
        homeView.collectionView.delegate = self
        homeView.toolbarDelegate = self
        homeView.selectionToolBar.delegate = self
        selectionBottomBar.delegate = self
    }

    private func setupBindings() {
        homeView.refreshAction = { [weak self] in
            self?.refreshItems()
        }

        // '전체 선택' 상태는 선택 개수가 그대로여도 바뀔 수 있어 함께 관찰합니다.
        Publishers.CombineLatest(selectionViewModel.$selectedItemIds, selectionViewModel.$isSelectAllOn)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _ in
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

    @objc func refreshItems() {
        viewModel.fetchItems(reset: true)
    }

    func scrollToTop() {
        homeView.collectionView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }

    private func setupBackgroundDimView() {
        backgroundDimView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        backgroundDimView.alpha = 0.0 // 초기에는 투명하게 설정
        view.addSubview(backgroundDimView)

        backgroundDimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupSelectionBottomBar() {
        view.addSubview(selectionBottomBar)
        selectionBottomBar.snp.makeConstraints { make in
            make.horizontalEdges.bottom.equalToSuperview()
            make.height.equalTo(ItemSelectionBottomBar.height + 34)
        }
    }

    private func setupBottomSheet() {

    }

    /// 앱 가이드 시트 노출
    private func showAppGuideSheet() {
        DispatchQueue.main.async {
            let guideVC = AppGuideSheetViewController()
            guideVC.modalPresentationStyle = .overFullScreen // 화면 전체 덮기
            guideVC.modalTransitionStyle = .crossDissolve // 부드러운 애니메이션

            guideVC.onDismiss = {
                UserManager.isFirstLogin = false
            }
            self.present(guideVC, animated: true)
        }
    }
}

// MARK: - 아이템 다중 선택

extension HomeViewController {

    private func enterSelectionMode() {
        selectionViewModel.enterSelectionMode()
        homeView.setSelectionMode(true)
        selectionBottomBar.isHidden = false
        tabBarController?.tabBar.isHidden = true
        updateSelectionBottomBar()
    }

    private func exitSelectionMode() {
        selectionViewModel.exitSelectionMode()
        homeView.setSelectionMode(false)
        selectionBottomBar.isHidden = true
        tabBarController?.tabBar.isHidden = false
    }

    private func updateSelectionBottomBar() {
        guard selectionViewModel.isSelectionMode else { return }
        selectionBottomBar.configure(
            selectedCount: deletionTargetCount,
            hasItems: !viewModel.displayedItems.isEmpty,
            isSelectAllOn: selectionViewModel.isSelectAllOn
        )
    }

    /// 현재 조회 조건('소장템 제외' 필터)에 해당하는 전체 아이템 개수
    private var filteredTotalCount: Int {
        viewModel.isExcludingOwned
        ? max(0, viewModel.totalCount - viewModel.ownedCount)
        : viewModel.totalCount
    }

    /// 실제로 삭제될 아이템 개수
    private var deletionTargetCount: Int {
        selectionViewModel.deletionTargetCount(filteredTotalCount: filteredTotalCount)
    }

    /// 일괄 삭제 요청 생성
    private func makeBulkDeleteRequest() -> BulkDeleteItemsRequest? {
        guard deletionTargetCount > 0 else { return nil }

        // 전체 선택 상태라면 아직 불러오지 않은 아이템도 대상이므로,
        // 화면의 조회 조건을 그대로 넘기고 개별 해제한 아이템만 제외합니다.
        if selectionViewModel.isSelectAllOn {
            return .all(
                itemStatus: viewModel.isExcludingOwned ? .wish : nil,
                excludeItemIds: Array(selectionViewModel.excludedItemIds)
            )
        }
        return .selected(itemIds: selectionViewModel.selectedItemIds.sorted())
    }

    /// 선택된 아이템 삭제
    private func requestDeleteSelectedItems() {
        guard let request = makeBulkDeleteRequest() else { return }

        AnalyticsManager.shared.log(
            .itemsBulkDeleted(source: .home,
                              scope: request.scope == .all ? .all : .selected,
                              itemCount: deletionTargetCount)
        )

        let indicator = ItemSelectionFlow.showLoading(on: self)

        Task { @MainActor [weak self] in
            guard let self = self else { return }
            defer { ItemSelectionFlow.hideLoading(indicator) }

            do {
                try await self.viewModel.deleteItems(request: request)

                self.exitSelectionMode()
                self.refreshItems()
                SnackBar.shared.show(type: .deleteItem)
            } catch let error as BulkDeleteItemsError {
                // 나눠 호출하던 중 실패한 경우. 이미 삭제된 아이템은 선택에서 빼고
                // 목록을 갱신해, 남은 선택 그대로 다시 시도할 수 있게 합니다.
                self.selectionViewModel.removeFromSelection(Set(error.deletedItemIds))
                self.refreshItems()
            } catch {
                // 실패 토스트는 ErrorPlugin에서 공통 처리합니다.
                // 선택 상태는 그대로 두어 다시 시도할 수 있게 합니다.
            }
        }
    }
}

extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.section == 1 else { return }
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
            detailViewController.hidesBottomBarWhenPushed = true

            detailViewController.editAction = { [weak self] updatedItem in
                guard let updatedItem = updatedItem else { return }
                if let idx = self?.viewModel.items.firstIndex(where: { $0.id == updatedItem.id }) {
                    self?.viewModel.items[idx] = updatedItem
                }
            }

            detailViewController.deleteAction = { [weak self] _ in
                self?.viewModel.items.removeAll { $0.id == item.id }
                Task { await self?.viewModel.fetchItemCounts() }
            }

            detailViewController.collectionChangeAction = { [weak self] isCollected in
                guard let self = self else { return }
                if let idx = self.viewModel.items.firstIndex(where: { $0.id == item.id }) {
                    self.viewModel.items[idx].itemStatus = isCollected ? .owned : .wish
                }
            }

            navigationController?.pushViewController(detailViewController, animated: true)
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        guard indexPath.section == 1 else { return }
        viewModel.loadNextIfNeeded(currentIndex: indexPath.item)
    }


}

extension HomeViewController: HomeToolBarDelegate {
    func alarmNaviItemTap() {
        UIDevice.vibrate()
        let nextVC = AlarmListViewController()
        nextVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(nextVC, animated: true)
    }

    func itemSelectNaviItemTap() {
        UIDevice.vibrate()
        enterSelectionMode()
    }
}

extension HomeViewController: ItemSelectionToolBarDelegate {
    func selectionCloseButtonTap() {
        exitSelectionMode()
    }
}

extension HomeViewController: ItemSelectionBottomBarDelegate {
    func selectionBarDidTapSelectAll() {
        selectionViewModel.selectAll(itemIds: homeView.displayedItemIds())
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
