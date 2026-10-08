//
//  FolderThumbnailViewController.swift
//  WishboardV2
//
//  Created by gomin on 10/8/26.
//

import Foundation
import UIKit
import SnapKit
import Combine
import Core
import WBNetwork

/// 폴더 > 더보기 > '대표 사진 변경'.
///
/// 폴더에 담긴 아이템의 이미지만 2열로 보여 주고, 그중 하나를 대표 사진으로 고릅니다.
final class FolderThumbnailViewController: UIViewController, AddToolBarDelegate {

    // MARK: - Views
    private let thumbnailView: FolderThumbnailView

    // MARK: - Properties
    /// 폴더 상세 화면과 같은 '폴더 아이템 리스트 조회'를 그대로 씁니다. (페이징 포함)
    private let viewModel: FolderDetailViewModel
    private let folderId: Int
    /// 진입 시점에 지정되어 있던 대표 사진 URL
    private let currentThumbnailUrl: String?

    /// 선택된 아이템. 하나는 반드시 선택된 상태를 유지합니다.
    private var selectedItemId: Int?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializers

    init(folderId: Int, folderTitle: String, currentThumbnailUrl: String?) {
        self.folderId = folderId
        self.currentThumbnailUrl = currentThumbnailUrl
        self.thumbnailView = FolderThumbnailView(folderTitle: folderTitle)
        self.viewModel = FolderDetailViewModel(folderId: String(folderId))
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        self.navigationController?.navigationBar.isHidden = true

        setupView()
        setupBindings()

        viewModel.fetchItems(reset: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    // MARK: - Setup

    private func setupView() {
        view.addSubview(thumbnailView)
        thumbnailView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.horizontalEdges.bottom.equalToSuperview()
        }

        thumbnailView.toolBar.delegate = self
        thumbnailView.collectionView.delegate = self
        thumbnailView.collectionView.dataSource = self
    }

    private func setupBindings() {
        viewModel.$items
            .receive(on: RunLoop.main)
            .sink { [weak self] items in
                guard let self = self else { return }
                self.applyInitialSelectionIfNeeded(with: items)
                self.thumbnailView.updateEmptyState(isEmpty: items.isEmpty)
                self.thumbnailView.collectionView.reloadData()
            }
            .store(in: &cancellables)

        // 아이템 리스트 조회 동안 로딩뷰 노출
        viewModel.$isInitialLoading
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] isLoading in
                self?.thumbnailView.setLoading(isLoading)
            }
            .store(in: &cancellables)
    }

    /// 화면 진입 시 기존 대표 사진을 선택된 상태로 보여 줍니다.
    ///
    /// 지금은 어떤 아이템이 대표 사진인지 내려주는 값이 없어, 폴더 썸네일 URL과 같은 이미지를 찾아 맞춰 둡니다.
    /// 서버에서 대표 아이템을 내려주게 되면 그 값으로 바꾸면 됩니다.
    private func applyInitialSelectionIfNeeded(with items: [WishListResponse]) {
        guard selectedItemId == nil, !items.isEmpty else { return }

        if let thumbnailUrl = currentThumbnailUrl,
           let matched = items.first(where: { $0.itemImages?.first?.itemImageUrl == thumbnailUrl }) {
            selectedItemId = matched.id
        } else {
            selectedItemId = items.first?.id
        }
    }

    // MARK: - AddToolBarDelegate

    /// 뒤로가기
    func leftItemTap() {
        UIDevice.vibrate()
        navigationController?.popViewController(animated: true)
    }

    /// 저장
    func rightItemTap() {
        UIDevice.vibrate()

        guard let selectedItemId = selectedItemId else { return }

        // TODO: 폴더 대표 사진 변경 API 연동 (folderId: \(folderId), itemId: \(selectedItemId))
        // 서버 작업이 끝나면 여기서 API를 호출하고, 성공 시 폴더 목록을 갱신한 뒤 화면을 닫습니다.
        print("폴더 대표 사진 변경 - folderId: \(folderId), itemId: \(selectedItemId)")

        navigationController?.popViewController(animated: true)
    }
}

// MARK: - CollectionView

extension FolderThumbnailViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: FolderThumbnailImageCell.reuseIdentifier,
            for: indexPath
        ) as? FolderThumbnailImageCell,
              indexPath.item < viewModel.items.count else {
            return UICollectionViewCell()
        }

        let item = viewModel.items[indexPath.item]
        cell.configure(with: item, isSelected: item.id == selectedItemId)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item < viewModel.items.count,
              let itemId = viewModel.items[indexPath.item].id else { return }
        // 이미 선택된 이미지를 다시 눌러도 선택은 풀리지 않습니다.
        guard itemId != selectedItemId else { return }

        UIDevice.vibrate()

        let previousItemId = selectedItemId
        selectedItemId = itemId

        var indexPaths = [indexPath]
        if let previousItemId = previousItemId,
           let previousIndex = viewModel.items.firstIndex(where: { $0.id == previousItemId }) {
            indexPaths.append(IndexPath(item: previousIndex, section: indexPath.section))
        }
        collectionView.reloadItems(at: indexPaths)
    }

    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        viewModel.loadNextIfNeeded(currentIndex: indexPath.item)
    }
}
