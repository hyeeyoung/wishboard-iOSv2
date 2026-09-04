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

    private var viewModel: HomeViewModel?
    private let refreshControl = UIRefreshControl()
    public var refreshAction: (() -> Void)?
    private weak var stickyHeader: HomeStickyHeaderView?
    private var isBannerVisible = true

    private var currentColumnType: GridColumnType = {
        GridColumnType(rawValue: UserManager.gridColumnType) ?? .two
    }()

    /// 툴바 델리게이트 - 스크롤 헤더에 전달됩니다
    weak var toolbarDelegate: HomeToolBarDelegate?

    // MARK: - Initializers
    override init(frame: CGRect) {
        let initialColumn = GridColumnType(rawValue: UserManager.gridColumnType) ?? .two
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: HomeView.makeLayout(columnType: initialColumn, isBannerVisible: true))
        collectionView.backgroundColor = .white
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.contentInset.bottom = 90

        super.init(frame: frame)

        currentColumnType = initialColumn
        setupViews()
        setupConstraints()
        setupRefreshControl()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout Factory

    private static func makeLayout(columnType: GridColumnType, isBannerVisible: Bool) -> UICollectionViewCompositionalLayout {
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
            HomeView.makeLayout(columnType: currentColumnType, isBannerVisible: false),
            animated: false
        )
        collectionView.reloadData()
    }

    private func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
    }

    @objc private func handleRefresh() {
        self.refreshAction?()
    }

    // MARK: - Public Methods
    func configure(with viewModel: HomeViewModel) {
        self.viewModel = viewModel

        viewModel.$displayedItems
            .receive(on: RunLoop.main)
            .sink { [weak self] items in
                self?.refreshControl.endRefreshing()
                self?.emptyLabel.isHidden = !(items.isEmpty)
                self?.collectionView.reloadData()
            }
            .store(in: &cancellables)

        Publishers.CombineLatest3(viewModel.$totalElements, viewModel.$hasOwnedItems, viewModel.$isExcludingOwned)
            .receive(on: RunLoop.main)
            .sink { [weak self] totalElements, hasOwnedItems, isExcluding in
                self?.stickyHeader?.configure(
                    totalCount: totalElements,
                    hasOwnedItems: hasOwnedItems,
                    isExcludingOwned: isExcluding
                )
            }
            .store(in: &cancellables)

        collectionView.dataSource = self
    }

    private var cancellables = Set<AnyCancellable>()
}

extension HomeView: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 1 ? (viewModel?.displayedItems.count ?? 0) : 0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        
        guard indexPath.section == 1,
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
                    totalCount: vm.totalElements,
                    hasOwnedItems: vm.hasOwnedItems,
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
            HomeView.makeLayout(columnType: column, isBannerVisible: isBannerVisible),
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
