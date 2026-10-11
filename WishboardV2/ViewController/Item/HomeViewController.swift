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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 로그인 직후처럼 포그라운드 전환 없이 들어오는 경우를 위해 여기서도 연결합니다.
        // 이미 연결 중이면 아무 일도 하지 않습니다.
        EventStreamManager.shared.start()
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
        // 실시간으로 내려오는 안읽은 알림 개수를 상단바 뱃지에 반영합니다.
        EventStreamManager.shared.$unreadCount
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] count in
                self?.homeView.updateAlarmBadge(count: count)
            }
            .store(in: &cancellables)

        // 당겨서 새로고침은 자체 인디케이터가 있어, 로딩뷰를 띄우지 않는 경로로 조회합니다.
        homeView.refreshAction = { [weak self] in
            self?.viewModel.refresh()
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

        // 위시리스트 조회 동안 로딩뷰 노출
        viewModel.$isInitialLoading
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] isLoading in
                self?.homeView.setLoading(isLoading)
            }
            .store(in: &cancellables)
    }

    @objc func refreshItems() {
        viewModel.fetchItems(reset: true)
    }

    /// 아이템 상세 화면으로 이동합니다.
    ///
    /// 상세에서의 수정 / 삭제 / 소장템 전환을 목록에 반영하는 연결도 함께 걸어 둡니다.
    /// 목록에서 탭했을 때와 새로 등록한 직후 모두 이 경로를 씁니다.
    func showItemDetail(for item: WishListResponse) {
        guard let itemIdx = item.id else { return }

        let detailViewController = ItemDetailViewController(id: itemIdx)
        detailViewController.hidesBottomBarWhenPushed = true

        detailViewController.editAction = { [weak self] updatedItem in
            guard let updatedItem = updatedItem else { return }
            if let idx = self?.viewModel.items.firstIndex(where: { $0.id == updatedItem.id }) {
                self?.viewModel.items[idx] = updatedItem
            }
        }

        detailViewController.deleteAction = { [weak self] _ in
            self?.viewModel.items.removeAll { $0.id == itemIdx }
            Task { await self?.viewModel.fetchItemCounts() }
        }

        detailViewController.collectionChangeAction = { [weak self] isCollected in
            guard let self = self else { return }
            if let idx = self.viewModel.items.firstIndex(where: { $0.id == itemIdx }) {
                self.viewModel.items[idx].itemStatus = isCollected ? .owned : .wish
            }
        }

        navigationController?.pushViewController(detailViewController, animated: true)
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
        homeView.onTapFilterChip = { [weak self] in
            self?.presentFilterSheet()
        }
    }

    /// 목록 필터 선택 바텀시트
    private func presentFilterSheet() {
        let sheet = ItemFilterBottomSheetViewController(selectedFilter: viewModel.filter)
        sheet.onSelect = { [weak self] filter in
            guard let self = self else { return }
            // 필터가 바뀌면 목록을 다시 조회하므로, 화면에서 사라질 아이템의 선택 상태를 정리합니다.
            self.selectionViewModel.clearSelection()
            self.viewModel.updateFilter(filter)
        }
        present(sheet, animated: false)
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
            totalCount: filteredTotalCount
        )
        // 메뉴에 들어갈 개수가 선택에 따라 달라지므로 매번 다시 만듭니다.
        selectionBottomBar.setMoreMenu(makeMoreMenu())
    }

    /// '더 보기' 메뉴
    ///
    /// 고른 아이템이 모두 위시템이면 '위시템으로 전환'은, 모두 소장템이면 '소장템으로 전환'은
    /// 바꿀 것이 없어 메뉴에서 뺍니다.
    private func makeMoreMenu() -> UIMenu {
        var children: [UIMenuElement] = []

        if conversionTargetCount(to: .wish) > 0 {
            children.append(ItemSelectionFlow.makeConvertAction(to: .wish) { [weak self] in
                self?.presentConvertAlert(to: .wish)
            })
        }

        if conversionTargetCount(to: .owned) > 0 {
            children.append(ItemSelectionFlow.makeConvertAction(to: .owned) { [weak self] in
                self?.presentConvertAlert(to: .owned)
            })
        }

        children.append(ItemSelectionFlow.makeDeleteAction { [weak self] in
            self?.presentDeleteAlert()
        })

        return UIMenu(title: "", children: children)
    }

    /// 현재 필터에 해당하는 전체 아이템 개수
    private var filteredTotalCount: Int {
        HomeView.displayedTotalCount(totalCount: viewModel.totalCount,
                                     ownedCount: viewModel.ownedCount,
                                     filter: viewModel.filter)
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
                itemStatus: viewModel.filter.itemStatus,
                excludeItemIds: Array(selectionViewModel.excludedItemIds)
            )
        }
        return .selected(itemIds: selectionViewModel.selectedItemIds.sorted())
    }

    /// 실제로 상태가 바뀔 아이템 개수.
    /// 이미 그 상태인 아이템은 바뀌지 않으므로, 반대 상태인 것만 셉니다.
    private func conversionTargetCount(to status: ItemStatusType) -> Int {
        let oppositeStatus: ItemStatusType = (status == .wish) ? .owned : .wish

        guard selectionViewModel.isSelectAllOn else {
            return viewModel.items
                .filter { item in
                    guard let id = item.id else { return false }
                    return selectionViewModel.selectedItemIds.contains(id)
                }
                .filter { $0.itemStatus == oppositeStatus }
                .count
        }

        // 전체 선택 상태에서는 아직 불러오지 않은 아이템까지 대상이라,
        // 서버가 내려준 개수에서 개별 해제한 아이템만 빼서 셉니다.
        let totalInScope = (oppositeStatus == .owned) ? ownedCountInScope : wishCountInScope
        let excludedCount = viewModel.items
            .filter { item in
                guard let id = item.id else { return false }
                return selectionViewModel.excludedItemIds.contains(id)
            }
            .filter { $0.itemStatus == oppositeStatus }
            .count

        return max(0, totalInScope - excludedCount)
    }

    /// '위시템만' 필터가 걸려 있으면 대상에 소장템이 없습니다.
    private var ownedCountInScope: Int {
        viewModel.filter == .wishOnly ? 0 : viewModel.ownedCount
    }

    /// '소장템만' 필터가 걸려 있으면 대상에 위시템이 없습니다.
    private var wishCountInScope: Int {
        viewModel.filter == .ownedOnly ? 0 : viewModel.wishCount
    }

    /// 상태 일괄 변경 요청 생성
    private func makeBulkUpdateStatusRequest(to status: ItemStatusType) -> BulkUpdateItemStatusRequest? {
        guard conversionTargetCount(to: status) > 0 else { return nil }

        if selectionViewModel.isSelectAllOn {
            return .all(
                status: status,
                itemStatus: viewModel.filter.itemStatus,
                excludeItemIds: Array(selectionViewModel.excludedItemIds)
            )
        }
        return .selected(status: status, itemIds: selectionViewModel.selectedItemIds.sorted())
    }

    private func presentConvertAlert(to status: ItemStatusType) {
        ItemSelectionFlow.presentConvertAlert(
            on: self,
            to: status,
            targetCount: conversionTargetCount(to: status)
        ) { [weak self] in
            self?.requestConvertSelectedItems(to: status)
        }
    }

    private func presentDeleteAlert() {
        ItemSelectionFlow.presentDeleteAlert(
            on: self,
            selectedCount: deletionTargetCount
        ) { [weak self] in
            self?.requestDeleteSelectedItems()
        }
    }

    /// 선택된 아이템의 상태 일괄 변경
    private func requestConvertSelectedItems(to status: ItemStatusType) {
        guard let request = makeBulkUpdateStatusRequest(to: status) else { return }

        homeView.showLoading()

        Task { @MainActor [weak self] in
            guard let self = self else { return }
            defer { self.homeView.hideLoading() }

            do {
                try await self.viewModel.updateItemsStatus(request: request)

                self.exitSelectionMode()
                self.refreshItems()
                SnackBar.shared.show(type: status == .wish ? .convertToWishItem : .convertToOwnedItem)
            } catch let error as BulkItemsPartialFailureError {
                // 나눠 호출하던 중 실패한 경우. 이미 바뀐 아이템은 선택에서 빼고
                // 목록을 갱신해, 남은 선택 그대로 다시 시도할 수 있게 합니다.
                self.selectionViewModel.removeFromSelection(Set(error.processedItemIds))
                self.refreshItems()
            } catch {
                // 실패 토스트는 ErrorPlugin에서 공통 처리합니다.
                // 선택 상태는 그대로 두어 다시 시도할 수 있게 합니다.
            }
        }
    }

    /// 선택된 아이템 삭제
    private func requestDeleteSelectedItems() {
        guard let request = makeBulkDeleteRequest() else { return }

        AnalyticsManager.shared.log(
            .itemsBulkDeleted(source: .home,
                              scope: request.scope == .all ? .all : .selected,
                              itemCount: deletionTargetCount)
        )

        homeView.showLoading()

        Task { @MainActor [weak self] in
            guard let self = self else { return }
            defer { self.homeView.hideLoading() }

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

        UIDevice.vibrate()
        showItemDetail(for: item)
    }

    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        guard indexPath.section == 1 else { return }
        // 미리 만들어 둔 셀은 선택이 바뀌어도 다시 구성되지 않으므로, 나타나기 직전에 맞춰줍니다.
        homeView.applySelectionAppearance(to: cell, at: indexPath)
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
}
