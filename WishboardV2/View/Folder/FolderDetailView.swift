//
//  FolderDetailView.swift
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


final class FolderDetailView: UIView, LoadingPresentable {

    // MARK: - Views
    public let toolbar = ToolBar()
    /// 다중 선택 모드에서 툴바/헤더 대신 노출되는 상단바
    public let selectionToolBar = ItemSelectionToolBar().then {
        $0.isHidden = true
    }
    /// 로딩뷰가 덮을 영역. 상단바는 가리지 않습니다.
    let loadingContainerView = UIView().then {
        $0.isUserInteractionEnabled = false
    }
    private var folderTitle: String?
    public let collectionView: UICollectionView
    private let emptyLabel = UILabel().then {
        $0.text = "앗, 아이템이 없어요!\n갖고 싶은 아이템을 등록해 보세요!"
        $0.setTypoStyleWithMultiLine(typoStyle: .SuitD2)
        $0.textColor = .gray_200
        $0.numberOfLines = 0
        $0.textAlignment = .center
        $0.isHidden = true
    }

    // MARK: - Properties

    /// 홈화면의 스티키헤더와 동일한 헤더이지만, 폴더 상세에서는 컬렉션뷰와 함께 스크롤됩니다.
    static let headerHeight: CGFloat = 36
    /// 아이템이 들어있는 섹션 인덱스
    private static let itemSection: Int = 0

    private var viewModel: FolderDetailViewModel?
    private var selectionViewModel: ItemSelectionViewModel?
    private let refreshControl = UIRefreshControl()
    public var refreshAction: (() -> Void)?
    private weak var header: HomeStickyHeaderView?
    private var isSelectionMode = false

    /// 드래그 선택 시작 시점의 선택 상태. 손가락을 되돌렸을 때 원래 상태로 복원하기 위해 사용합니다.
    private var dragStartSelection: Set<Int> = []
    private var dragSelectionController: ItemDragSelectionController?

    private var currentColumnType: GridColumnType = {
        GridColumnType(rawValue: UserManager.gridColumnType) ?? .two
    }()

    // MARK: - Initializers

    override init(frame: CGRect) {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.backgroundColor = .white

        super.init(frame: frame)
    }

    convenience init(folderTitle: String) {
        self.init()
        self.folderTitle = folderTitle

        setupViews()
        setupConstraints()
        setupDragSelection()
        applyLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        addSubview(toolbar)
        addSubview(selectionToolBar)
        addSubview(collectionView)
        addSubview(emptyLabel)
        addSubview(loadingContainerView)

        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.register(
            WishItemCollectionViewCell.self,
            forCellWithReuseIdentifier: WishItemCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            HomeStickyHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: HomeStickyHeaderView.reuseIdentifier
        )
    }

    private func setupConstraints() {
        toolbar.configure(title: folderTitle ?? "", showsItemSelectButton: true)

        selectionToolBar.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
            make.height.equalTo(ItemSelectionToolBar.height)
        }

        collectionView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalTo(toolbar.snp.bottom)
            make.bottom.equalToSuperview()
        }

        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        loadingContainerView.snp.makeConstraints { make in
            make.horizontalEdges.bottom.equalToSuperview()
            make.top.equalTo(toolbar.snp.bottom)
        }
    }

    private func setupDragSelection() {
        let controller = ItemDragSelectionController(collectionView: collectionView, section: FolderDetailView.itemSection)
        controller.delegate = self
        dragSelectionController = controller
    }

    /// 열 수 / 선택 모드에 맞춰 플로우 레이아웃을 갱신합니다.
    private func applyLayout() {
        let layout = UICollectionViewFlowLayout()
        let screenWidth = UIScreen.main.bounds.width
        let count = CGFloat(currentColumnType.rawValue)
        let cellWidth = screenWidth / count

        switch currentColumnType {
        case .one:
            layout.itemSize = CGSize(width: screenWidth, height: 104)
        case .two:
            layout.itemSize = CGSize(width: cellWidth, height: cellWidth * 1.5)
        case .three:
            layout.itemSize = CGSize(width: cellWidth, height: cellWidth * 1.88)
        }

        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        // 헤더는 다중 선택 모드에서도 노출되며, 선택 모드에서는 x버튼 바 바로 아래에 붙습니다.
        layout.headerReferenceSize = CGSize(width: screenWidth, height: FolderDetailView.headerHeight)

        collectionView.setCollectionViewLayout(layout, animated: false)
        collectionView.reloadData()
    }

    @objc private func handleRefresh() {
        self.refreshAction?()
    }

    // MARK: - Public Methods
    func configure(with viewModel: FolderDetailViewModel, selectionViewModel: ItemSelectionViewModel) {
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

        // 전체 아이템 개수는 서버 응답(totalElements)을 그대로 사용합니다.
        Publishers.CombineLatest(viewModel.$totalCount, viewModel.$isExcludingOwned)
            .receive(on: RunLoop.main)
            .sink { [weak self] totalCount, isExcludingOwned in
                self?.header?.configure(totalCount: totalCount, isExcludingOwned: isExcludingOwned)
            }
            .store(in: &cancellables)

        selectionViewModel.$selectedItemIds
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateSelectionAppearance()
            }
            .store(in: &cancellables)

        collectionView.dataSource = self
    }

    /// 다중 선택 모드 진입/종료에 따라 상단바와 헤더를 전환합니다.
    func setSelectionMode(_ isSelectionMode: Bool) {
        guard self.isSelectionMode != isSelectionMode else { return }
        self.isSelectionMode = isSelectionMode

        toolbar.isHidden = isSelectionMode
        selectionToolBar.isHidden = !isSelectionMode
        dragSelectionController?.isEnabled = isSelectionMode

        collectionView.snp.remakeConstraints { make in
            make.horizontalEdges.bottom.equalToSuperview()
            make.top.equalTo(isSelectionMode ? selectionToolBar.snp.bottom : toolbar.snp.bottom)
        }
        // 로딩뷰도 노출 중인 상단바 아래에서 시작하도록 맞춥니다.
        loadingContainerView.snp.remakeConstraints { make in
            make.horizontalEdges.bottom.equalToSuperview()
            make.top.equalTo(isSelectionMode ? selectionToolBar.snp.bottom : toolbar.snp.bottom)
        }
        // 선택 하단바에 마지막 아이템이 가려지지 않도록 여백을 둡니다.
        collectionView.contentInset.bottom = isSelectionMode ? (ItemSelectionBottomBar.height + 34) : 0

        applyLayout()
        collectionView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
    }

    /// 현재 화면에 노출 중인 아이템 id 목록
    func displayedItemIds() -> [Int] {
        viewModel?.displayedItems.compactMap { $0.id } ?? []
    }

    // MARK: - Private Methods

    private func itemId(at indexPath: IndexPath) -> Int? {
        guard indexPath.section == FolderDetailView.itemSection,
              let items = viewModel?.displayedItems,
              items.indices.contains(indexPath.row) else { return nil }
        return items[indexPath.row].id
    }

    /// 선택 상태가 바뀔 때마다 전체를 다시 그리지 않고, 보이는 셀만 갱신합니다.
    private func updateSelectionAppearance() {
        for cell in collectionView.visibleCells {
            guard let indexPath = collectionView.indexPath(for: cell) else { continue }
            applySelectionAppearance(to: cell, at: indexPath)
        }
    }

    /// 셀 하나의 선택 표시를 현재 상태에 맞춰 갱신합니다.
    ///
    /// 컬렉션뷰가 미리 만들어 둔(프리페치) 셀은 화면 밖에 있어 `visibleCells` 에 잡히지 않습니다.
    /// 그래서 그 사이에 선택이 바뀌면 갱신에서 빠지고, 스크롤해서 나타날 때는 이미 만들어진 셀이라
    /// `cellForItemAt` 도 다시 불리지 않아 예전 상태 그대로 보입니다.
    /// 화면에 나타나기 직전(`willDisplay`)에도 이 메서드를 호출해 상태를 맞춰야 합니다.
    func applySelectionAppearance(to cell: UICollectionViewCell, at indexPath: IndexPath) {
        guard let itemCell = cell as? WishItemCollectionViewCell else { return }

        var isItemSelected = false
        if let id = itemId(at: indexPath) {
            isItemSelected = selectionViewModel?.isSelected(id) ?? false
        }
        itemCell.configureSelection(isSelectionMode: isSelectionMode, isSelected: isItemSelected)
    }

    private var cancellables = Set<AnyCancellable>()
}

extension FolderDetailView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.displayedItems.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WishItemCollectionViewCell.reuseIdentifier, for: indexPath) as? WishItemCollectionViewCell else {
            return UICollectionViewCell()
        }

        guard let items = viewModel?.displayedItems,
              items.indices.contains(indexPath.row) else {
            return cell
        }

        let item = items[indexPath.row]
        cell.configure(with: item, columnType: currentColumnType)

        applySelectionAppearance(to: cell, at: indexPath)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
              let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: HomeStickyHeaderView.reuseIdentifier,
                for: indexPath
              ) as? HomeStickyHeaderView else {
            return UICollectionReusableView()
        }

        header.delegate = self
        self.header = header

        if let viewModel = viewModel {
            header.configure(
                totalCount: viewModel.totalCount,
                isExcludingOwned: viewModel.isExcludingOwned
            )
        }
        return header
    }
}

extension FolderDetailView: HomeStickyHeaderDelegate {
    func didToggleExcludeOwned() {
        // 필터가 바뀌면 목록을 다시 조회하므로, 화면에서 사라질 아이템의 선택 상태를 정리합니다.
        selectionViewModel?.clearSelection()
        viewModel?.toggleExcludeOwned()
    }

    func didChangeGridColumn(_ column: GridColumnType) {
        currentColumnType = column
        applyLayout()
        collectionView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
    }
}

// MARK: - ItemDragSelectionControllerDelegate

extension FolderDetailView: ItemDragSelectionControllerDelegate {
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
