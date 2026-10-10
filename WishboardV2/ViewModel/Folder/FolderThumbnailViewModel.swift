//
//  FolderThumbnailViewModel.swift
//  WishboardV2
//
//  Created by gomin on 10/9/26.
//

import Foundation
import Combine
import WBNetwork
import Moya

/// 폴더 대표 사진 변경 화면의 상태.
///
/// 폴더에 담긴 아이템 중 이미지가 있는 것만 내려오며, 그중 하나를 대표 사진으로 고릅니다.
final class FolderThumbnailViewModel {

    /// 대표 사진 후보 이미지들
    @Published private(set) var images: [FolderThumbnailImageResponse] = []
    /// 선택된 이미지의 itemImageId. 선택을 해제하면 nil이 됩니다.
    @Published private(set) var selectedItemImageId: Int?
    /// 진입 시점에 적용되어 있던 대표 사진. 저장할 것이 있는지 판단하는 기준입니다.
    private var initialSelectedItemImageId: Int?

    /// 진입했을 때와 달라진 것이 있는지 여부
    var hasChanges: Bool {
        selectedItemImageId != initialSelectedItemImageId
    }

    private(set) var folderId: String

    // Paging
    @Published private(set) var isInitialLoading: Bool = false
    private var isLoading: Bool = false
    private var hasMore: Bool = true
    private var page: Int = 0          // 서버의 data.number (0-based)
    private let pageSize: Int = 10     // 서버의 data.size와 일치

    /// 진입 시 서버가 내려준 선택 상태를 한 번만 반영하기 위한 플래그
    private var hasAppliedInitialSelection = false

    init(folderId: String) {
        self.folderId = folderId
    }

    // MARK: - 조회

    /// 대표 사진 후보 이미지 조회
    func fetchImages(reset: Bool = false) {
        guard !isLoading, hasMore || reset else { return }
        isLoading = true
        // 이미 보여 줄 목록이 있다면 로딩뷰를 띄우지 않습니다.
        isInitialLoading = reset && images.isEmpty

        if reset {
            page = 0
            hasMore = true
        }

        _Concurrency.Task {
            do {
                let usecase = GetFolderThumbnailImagesUseCase()
                let response = try await usecase.execute(folderId: folderId, page: page, size: pageSize)

                if reset { images.removeAll() }

                if let contents = response.data?.content {
                    images.append(contentsOf: contents)
                    applyInitialSelectionIfNeeded(with: contents)
                }

                hasMore = !(response.data?.last ?? true)
                if hasMore { page += 1 }

                isLoading = false
                isInitialLoading = false
            } catch {
                if reset { images = [] }
                isLoading = false
                isInitialLoading = false

                if let moyaError = error as? MoyaError, let response = moyaError.response {
                    if response.statusCode == 404 {
                        self.images = []
                    }
                }
            }
        }
    }

    /// 다음 페이지 로드
    func loadNextIfNeeded(currentIndex: Int, threshold: Int = 2) {
        guard currentIndex >= images.count - threshold else { return }
        fetchImages()
    }

    /// 진입 시 현재 적용된 대표 사진을 선택된 상태로 보여 줍니다.
    ///
    /// `selected`는 현재 적용된 이미지 하나에만 true로 내려옵니다.
    /// 지정된 대표 사진이 없다면 아무것도 선택하지 않습니다.
    private func applyInitialSelectionIfNeeded(with contents: [FolderThumbnailImageResponse]) {
        guard !hasAppliedInitialSelection else { return }

        if let selected = contents.first(where: { $0.selected == true }) {
            selectedItemImageId = selected.itemImageId
            initialSelectedItemImageId = selected.itemImageId
            hasAppliedInitialSelection = true
        }
    }

    // MARK: - 선택

    /// 이미지 선택. 이미 선택된 이미지를 다시 고르면 선택이 해제됩니다.
    func toggleSelection(itemImageId: Int) {
        // 서버가 내려준 선택 상태는 더 이상 덮어쓰지 않습니다.
        hasAppliedInitialSelection = true
        selectedItemImageId = (selectedItemImageId == itemImageId) ? nil : itemImageId
    }

    // MARK: - 저장

    /// 선택한 이미지를 대표 사진으로 지정합니다.
    /// 선택이 해제된 상태라면 기본 대표 사진으로 되돌립니다.
    func saveThumbnail() async throws {
        if let itemImageId = selectedItemImageId {
            let usecase = SetFolderThumbnailUseCase()
            _ = try await usecase.execute(folderId: folderId, itemImageId: itemImageId)
        } else {
            let usecase = DeleteFolderThumbnailUseCase()
            _ = try await usecase.execute(folderId: folderId)
        }
    }
}
