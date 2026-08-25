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
    public let toolbar = HomeToolBar()
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

    static let toolbarHeight: CGFloat = 52
    static let stickyHeaderHeight: CGFloat = 44

    private var viewModel: HomeViewModel?
    private let refreshControl = UIRefreshControl()
    public var refreshAction: (() -> Void)?
    private weak var stickyHeader: HomeStickyHeaderView?

    // MARK: - Initializers
    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        let cellWidth = UIScreen.main.bounds.width / 2
        layout.itemSize = CGSize(width: cellWidth, height: cellWidth + 70)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.headerReferenceSize = CGSize(width: UIScreen.main.bounds.width, height: HomeView.stickyHeaderHeight)
        layout.sectionHeadersPinToVisibleBounds = true

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(top: HomeView.toolbarHeight, left: 0, bottom: 0, right: 0)
        collectionView.contentInsetAdjustmentBehavior = .never

        super.init(frame: frame)

        setupViews()
        setupConstraints()
        setupRefreshControl()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        addSubview(collectionView)
        addSubview(emptyLabel)
        addSubview(toolbar)

        collectionView.register(WishItemCollectionViewCell.self, forCellWithReuseIdentifier: WishItemCollectionViewCell.reuseIdentifier)
        collectionView.register(HomeStickyHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: HomeStickyHeaderView.reuseIdentifier)
    }

    private func setupConstraints() {
        toolbar.configure()

        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        emptyLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(HomeView.toolbarHeight / 2)
        }
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
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.displayedItems.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WishItemCollectionViewCell.reuseIdentifier, for: indexPath) as? WishItemCollectionViewCell else {
            return UICollectionViewCell()
        }

        if let item = viewModel?.displayedItems[indexPath.row] {
            cell.configure(with: item)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
              let header = collectionView.dequeueReusableSupplementaryView(
                  ofKind: kind,
                  withReuseIdentifier: HomeStickyHeaderView.reuseIdentifier,
                  for: indexPath) as? HomeStickyHeaderView else {
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

extension HomeView: HomeStickyHeaderDelegate {
    func didToggleExcludeOwned() {
        viewModel?.toggleExcludeOwned()
    }
}
