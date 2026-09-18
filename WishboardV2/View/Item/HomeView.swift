//
//  HomeView.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation
import UIKit
import SnapKit
import Then
import Combine
import Core

final class HomeView: UIView {

    // MARK: - Views
    public let collectionView: UICollectionView
    public let eventBannerView = HomeEventBannerView()
    /// 다중 선택 모드에서 툴바/스티키헤더 대신 노출되는 상단바
    public let selectionToolBar = ItemSelectionToolBar().then {
        $0.isHidden = true
    }
    private let emptyLabel = UILabel().then {
        $0.text = "앗, 아이템이 없어요!\n갖고 싶은 아이템을 등록해 보세요!"
        $0.setTypoStyleWithMultiLine(typoStyle: .SuitD2)
        $0.textColor = .gray_200
        $0.numberOfLines = 0
        $0.textAlignment = .center
        $0.isHidden = true
    }

    // MARK: - Properties

    static let toolbarHeight: CGFloat = 52
    static let stickyHeaderHeight: CGFloat = 36
    static let eventBannerHeight: CGFloat = 36

    /// 아이템 섹션 인덱스 (0번 섹션은 툴바 헤더 전용)
    private static let itemSection: Int = 1

    private var viewModel: HomeViewModel?
    private var selectionViewModel: ItemSelectionViewModel?
    private let refreshControl = UIRefreshControl()
    public var refreshAction: (() -> Void)?
    private weak var stickyHeader: HomeStickyHeaderView?
    private var isBannerVisible = true
    private var isSelectionMode = false

    /// 드래그 선택 시작 시점의 선택 상태. 손가락을 되돌렸을 때 원래 상태로 복원하기 위해 사용합니다.
    private var dragStartSelection: Set<Int> = []
    private var dragSelectionController: ItemDragSelectionController?

    private var currentColumnType: GridColumnType = {
        GridColumnType(rawValue: UserManager.gridColumnType) ?? .two
    }()

    /// 툴바 델리게이트 - 스크롤 헤더에 전달됩니다
    weak var toolbarDelegate: HomeToolBarDelegate?

    // MARK: - Initializers
    override init(frame: CGRect) {
        let initialColumn = GridColumnType(rawValue: UserManager.gridColumnType) ?? .two
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: HomeView.makeLayout(columnType: initialColumn, isBannerVisible: true, isSelectionMode: false))
        collectionView.backgroundColor = .white
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.contentInset.bottom = 90

        super.init(frame: frame)

        currentColumnType = initialColumn
        setupViews()
        setupConstraints()
        setupRefreshControl()
        setupDragSelection()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout Factory

    private static func makeLayout(columnType: GridColumnType, isBannerVisible: Bool, isSelectionMode: Bool) -> UICollectionViewCompositionalLayout {
        let col = columnType
        return UICollectionViewCompositionalLayout { sectionIndex, _ in
            if sectionIndex == 0 {
                // Section 0: 툴바(+이벤트 배너) 헤더만 있는 섹션 (스크롤과 함께 사라짐)
                let dummyItem = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(0))
                )
                let dummyGroup = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(0)),
                    subitems: [dummyItem]
                )
                let section = NSCollectionLayoutSection(group: dummyGroup)

                // 다중 선택 모드에서는 로고 툴바와 이벤트 배너를 노출하지 않습니다.
                guard !isSelectionMode else { return section }

                let bannerHeight = isBannerVisible ? HomeView.eventBannerHeight : 0
                let toolbarHeader = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .absolute(HomeView.toolbarHeight + bannerHeight)
                    ),
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                toolbarHeader.pinToVisibleBounds = false
                section.boundarySupplementaryItems = [toolbarHeader]
                return section
            } else {
                // Section 1: 스티키헤더 + 그리드 아이템 (열 수에 따라 동적)
                let screenWidth = UIScreen.main.bounds.width
                let count = col.rawValue

                var cellHeight: CGFloat = 104
                switch col {
                case .one:
                    cellHeight = 104
                case .two:
                    cellHeight = (screenWidth / CGFloat(count)) * 1.5
                case .three:
                    cellHeight = (screenWidth / CGFloat(count)) * 1.88
                }

                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0 / CGFloat(count)),
                        heightDimension: .absolute(cellHeight)
                    )
                )
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .absolute(cellHeight)
                    ),
                    repeatingSubitem: item,
                    count: count
                )
                let section = NSCollectionLayoutSection(group: group)

                // 다중 선택 모드에서는 스티키헤더를 노출하지 않습니다.
                guard !isSelectionMode else { return section }

                let stickyHeader = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .absolute(HomeView.stickyHeaderHeight)
                    ),
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                stickyHeader.pinToVisibleBounds = true
                section.boundarySupplementaryItems = [stickyHeader]
                return section
            }
        }
    }

    // MARK: - Setup
    private func setupViews() {
        addSubview(collectionView)
        addSubview(selectionToolBar)
        addSubview(emptyLabel)

        collectionView.register(
            WishItemCollectionViewCell.self,
            forCellWithReuseIdentifier: WishItemCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            HomeToolBarHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: HomeToolBarHeaderView.reuseIdentifier
        )
        collectionView.register(
            HomeStickyHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: HomeStickyHeaderView.reuseIdentifier
        )
    }

    private func setupConstraints() {
        selectionToolBar.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
            make.height.equalTo(ItemSelectionToolBar.height)
        }
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        emptyLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(HomeView.toolbarHeight / 2)
        }
    }

    func hideEventBanner() {
        isBannerVisible = false
        eventBannerView.removeFromSuperview()

        collectionView.setCollectionViewLayout(
            HomeView.makeLayout(
                columnType: currentColumnType,
                isBannerVisible: false,
                isSelectionMode: isSelectionMode
            ),
            animated: false
        )

        collectionView.layoutIfNeeded()

        collectionView.setContentOffset(
            CGPoint(x: 0, y: 0),
            animated: false
        )

        collectionView.reloadData()
    }

    private func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
    }

    private func setupDragSelection() {
        let controller = ItemDragSelectionController(collectionView: collectionView, section: HomeView.itemSection)
        controller.delegate = self
        dragSelectionController = controller
    }

    @objc private func handleRefresh() {
        self.refreshAction?()
    }

    // MARK: - Public Methods
    func configure(with viewModel: HomeViewModel, selectionViewModel: ItemSelectionViewModel) {
        self.viewModel = viewModel
        self.selectionViewModel = selectionViewModel

        viewModel.$displayedItems
            .receive(on: RunLoop.main)
            .sink { [weak self] items in
                guard let self = self else { return }
                self.refreshControl.endRefreshing()
                self.emptyLabel.isHidden = !(items.isEmpty)
                // 전체 선택 상태라면 페이징으로 새로 불러온 아이템도 선택 상태로 유지합니다.
                selectionViewModel.applySelectAllIfNeeded(itemIds: items.compactMap { $0.id })
                self.collectionView.reloadData()
            }
            .store(in: &cancellables)

        selectionViewModel.$selectedItemIds
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateSelectionAppearance()
            }
            .store(in: &cancellables)

        Publishers.CombineLatest3(viewModel.$totalCount, viewModel.$ownedCount, viewModel.$isExcludingOwned)
            .receive(on: RunLoop.main)
            .sink { [weak self] totalCount, ownedCount, isExcluding in
                self?.stickyHeader?.configure(
                    totalCount: isExcluding ? (totalCount - ownedCount) : totalCount,
                    isExcludingOwned: isExcluding
                )
            }
            .store(in: &cancellables)

        collectionView.dataSource = self
    }

    /// 다중 선택 모드 진입/종료에 따라 상단바와 레이아웃을 전환합니다.
    func setSelectionMode(_ isSelectionMode: Bool) {
        guard self.isSelectionMode != isSelectionMode else { return }
        self.isSelectionMode = isSelectionMode

        selectionToolBar.isHidden = !isSelectionMode
        dragSelectionController?.isEnabled = isSelectionMode

        collectionView.refreshControl = isSelectionMode ? nil : refreshControl
        collectionView.snp.remakeConstraints { make in
            make.horizontalEdges.bottom.equalToSuperview()
            make.top.equalTo(isSelectionMode ? selectionToolBar.snp.bottom : self.snp.top)
        }

        collectionView.setCollectionViewLayout(
            HomeView.makeLayout(
                columnType: currentColumnType,
                isBannerVisible: isBannerVisible,
                isSelectionMode: isSelectionMode
            ),
            animated: false
        )
        collectionView.layoutIfNeeded()
        collectionView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        collectionView.reloadData()
    }

    /// 현재 화면에 노출 중인 아이템 id 목록
    func displayedItemIds() -> [Int] {
        viewModel?.displayedItems.compactMap { $0.id } ?? []
    }

    // MARK: - Private Methods

    private func itemId(at indexPath: IndexPath) -> Int? {
        guard indexPath.section == HomeView.itemSection,
              let items = viewModel?.displayedItems,
              items.indices.contains(indexPath.row) else { return nil }
        return items[indexPath.row].id
    }

    /// 선택 상태가 바뀔 때마다 전체를 다시 그리지 않고, 보이는 셀만 갱신합니다.
    private func updateSelectionAppearance() {
        guard let selectionViewModel = selectionViewModel else { return }

        for cell in collectionView.visibleCells {
            guard let itemCell = cell as? WishItemCollectionViewCell,
                  let indexPath = collectionView.indexPath(for: cell),
                  let id = itemId(at: indexPath) else { continue }
            itemCell.configureSelection(
                isSelectionMode: selectionViewModel.isSelectionMode,
                isSelected: selectionViewModel.isSelected(id)
            )
        }
    }

    private var cancellables = Set<AnyCancellable>()
}

extension HomeView: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == HomeView.itemSection ? (viewModel?.displayedItems.count ?? 0) : 0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        guard indexPath.section == HomeView.itemSection,
              let cell = collectionView.dequeueReusableCell(
                  withReuseIdentifier: WishItemCollectionViewCell.reuseIdentifier,
                  for: indexPath
              ) as? WishItemCollectionViewCell else {
            return UICollectionViewCell()
        }

        guard let items = viewModel?.displayedItems,
              items.indices.contains(indexPath.row) else {
            return cell
        }

        let item = items[indexPath.row]
        cell.configure(with: item, columnType: currentColumnType)

        var isItemSelected = false
        if let id = item.id {
            isItemSelected = selectionViewModel?.isSelected(id) ?? false
        }
        cell.configureSelection(isSelectionMode: isSelectionMode, isSelected: isItemSelected)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }

        if indexPath.section == 0 {
            guard let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: HomeToolBarHeaderView.reuseIdentifier,
                for: indexPath
            ) as? HomeToolBarHeaderView else {
                return UICollectionReusableView()
            }
            header.toolBar.delegate = toolbarDelegate
            header.configure(
                banner: isBannerVisible ? eventBannerView : nil,
                bannerHeight: HomeView.eventBannerHeight
            )
            return header
        } else {
            guard let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: HomeStickyHeaderView.reuseIdentifier,
                for: indexPath
            ) as? HomeStickyHeaderView else {
                return UICollectionReusableView()
            }

            header.delegate = self
            stickyHeader = header

            if let vm = viewModel {
                header.configure(
                    totalCount: vm.isExcludingOwned ? (vm.totalCount - vm.ownedCount) : vm.totalCount,
                    isExcludingOwned: vm.isExcludingOwned
                )
            }
            return header
        }
    }
}

extension HomeView: HomeStickyHeaderDelegate {
    func didToggleExcludeOwned() {
        viewModel?.toggleExcludeOwned()
    }

    func didChangeGridColumn(_ column: GridColumnType) {
        currentColumnType = column
        collectionView.setCollectionViewLayout(
            HomeView.makeLayout(columnType: column, isBannerVisible: isBannerVisible, isSelectionMode: isSelectionMode),
            animated: false
        )
        collectionView.layoutIfNeeded()
        collectionView.setContentOffset(
            CGPoint(
                x: 0,
                y: -collectionView.adjustedContentInset.top
            ),
            animated: false
        )
        collectionView.reloadData()
    }
}

// MARK: - ItemDragSelectionControllerDelegate

extension HomeView: ItemDragSelectionControllerDelegate {
    func dragSelectionController(_ controller: ItemDragSelectionController, isItemSelectedAt indexPath: IndexPath) -> Bool {
        guard let id = itemId(at: indexPath) else { return false }
        return selectionViewModel?.isSelected(id) ?? false
    }

    func dragSelectionControllerDidBegin(_ controller: ItemDragSelectionController) {
        dragStartSelection = selectionViewModel?.selectedItemIds ?? []
    }

    func dragSelectionController(_ controller: ItemDragSelectionController, didDragOver indexPaths: [IndexPath], isSelected: Bool) {
        let draggedIds = Set(indexPaths.compactMap { itemId(at: $0) })
        var updated = dragStartSelection
        if isSelected {
            updated.formUnion(draggedIds)
        } else {
            updated.subtract(draggedIds)
        }
        selectionViewModel?.updateSelection(updated)
    }

    func dragSelectionControllerDidEnd(_ controller: ItemDragSelectionController) {
        dragStartSelection = []
    }
}
