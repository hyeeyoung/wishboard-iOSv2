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
/// 폴더에 담긴 아이템 중 이미지가 있는 것만 2열로 보여 주고, 그중 하나를 대표 사진으로 고릅니다.
final class FolderThumbnailViewController: UIViewController, AddToolBarDelegate {

    // MARK: - Views
    private let thumbnailView: FolderThumbnailView

    // MARK: - Properties
    private let viewModel: FolderThumbnailViewModel
    private var cancellables = Set<AnyCancellable>()

    /// 직전에 선택되어 있던 이미지. 선택이 바뀐 셀만 다시 그리기 위해 들고 있습니다.
    private var lastSelectedItemImageId: Int?
    /// 저장 요청이 끝나기 전에 버튼이 다시 눌리는 것을 막습니다.
    private var isSaving = false

    // MARK: - Initializers

    init(folderId: Int, folderTitle: String) {
        self.thumbnailView = FolderThumbnailView(folderTitle: folderTitle)
        self.viewModel = FolderThumbnailViewModel(folderId: String(folderId))
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

        viewModel.fetchImages(reset: true)
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
        viewModel.$images
            .receive(on: RunLoop.main)
            .sink { [weak self] images in
                guard let self = self else { return }
                self.thumbnailView.updateEmptyState(isEmpty: images.isEmpty)
                self.updateSaveButtonState()
                self.thumbnailView.collectionView.reloadData()
            }
            .store(in: &cancellables)

        viewModel.$selectedItemImageId
            .receive(on: RunLoop.main)
            .sink { [weak self] selectedId in
                guard let self = self else { return }
                self.reloadSelection(from: self.lastSelectedItemImageId, to: selectedId)
                self.lastSelectedItemImageId = selectedId
                self.updateSaveButtonState()
            }
            .store(in: &cancellables)

        // 이미지 조회 동안 로딩뷰 노출
        viewModel.$isInitialLoading
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] isLoading in
                self?.thumbnailView.setLoading(isLoading)
            }
            .store(in: &cancellables)
    }

    /// 저장할 것이 있을 때만 버튼을 활성화합니다.
    /// 진입했을 때와 같은 상태로 되돌려 놓으면 다시 비활성이 됩니다.
    private func updateSaveButtonState() {
        thumbnailView.updateSaveButtonState(enabled: viewModel.hasChanges)
    }

    /// 선택이 바뀐 셀만 다시 그립니다. 전체를 갱신하면 이미지까지 다시 그려집니다.
    private func reloadSelection(from previousId: Int?, to newId: Int?) {
        let collectionView = thumbnailView.collectionView
        let itemCount = collectionView.numberOfItems(inSection: 0)

        let indexes = [previousId, newId]
            .compactMap { $0 }
            .compactMap { id in viewModel.images.firstIndex(where: { $0.itemImageId == id }) }
            .filter { $0 < itemCount }

        let indexPaths = Set(indexes).map { IndexPath(item: $0, section: 0) }
        guard !indexPaths.isEmpty else { return }

        collectionView.reloadItems(at: indexPaths)
    }

    // MARK: - AddToolBarDelegate

    /// 뒤로가기
    func leftItemTap() {
        UIDevice.vibrate()
        navigationController?.popViewController(animated: true)
    }

    /// 저장
    ///
    /// 고른 이미지가 있으면 대표 사진으로 지정하고, 선택을 해제한 상태라면 기본 대표 사진으로 되돌립니다.
    func rightItemTap() {
        guard !isSaving else { return }
        UIDevice.vibrate()
        isSaving = true

        _Concurrency.Task {
            do {
                try await viewModel.saveThumbnail()
                isSaving = false
                // 폴더 목록은 되돌아갈 때 다시 조회되어 바뀐 대표 사진이 바로 반영됩니다.
                navigationController?.popViewController(animated: true)
            } catch {
                isSaving = false
                SnackBar.shared.show(type: .errorMessage)
            }
        }
    }
}

// MARK: - CollectionView

extension FolderThumbnailViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.images.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: FolderThumbnailImageCell.reuseIdentifier,
            for: indexPath
        ) as? FolderThumbnailImageCell,
              indexPath.item < viewModel.images.count else {
            return UICollectionViewCell()
        }

        let image = viewModel.images[indexPath.item]
        let isSelected = (image.itemImageId != nil && image.itemImageId == viewModel.selectedItemImageId)
        cell.configure(with: image, isSelected: isSelected)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item < viewModel.images.count,
              let itemImageId = viewModel.images[indexPath.item].itemImageId else { return }

        UIDevice.vibrate()
        // 같은 이미지를 다시 고르면 선택이 해제됩니다.
        viewModel.toggleSelection(itemImageId: itemImageId)
    }

    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        viewModel.loadNextIfNeeded(currentIndex: indexPath.item)
    }
}
