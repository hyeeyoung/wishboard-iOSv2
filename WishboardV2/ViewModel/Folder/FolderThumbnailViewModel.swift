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
    ///
    /// 서버는 `selected` 를 그 이미지가 담긴 페이지에만 내려줍니다.
    /// 지정된 대표 사진이 뒷 페이지에 있다면, 그 페이지를 불러오기 전까지는
    /// 기준을 알 수 없다는 뜻입니다.
    private var initialSelectedItemImageId: Int?
    /// 기준이 되는 대표 사진을 찾았는지 여부
    private var hasFoundInitialSelection = false
    /// 사용자가 한 번이라도 선택을 건드렸는지 여부
    private var hasUserInteracted = false

    /// 기준값을 확정할 수 있는 상태인지.
    ///
    /// 지정된 대표 사진을 찾았거나, 마지막 페이지까지 불러왔는데도 없다면
    /// (= 지정된 대표 사진이 없다면) 확정입니다.
    private var isInitialSelectionResolved: Bool {
        hasFoundInitialSelection || !hasMore
    }

    /// 진입했을 때와 달라진 것이 있는지 여부
    var hasChanges: Bool {
        guard isInitialSelectionResolved else {
            // 아직 기준을 모르는 동안에는, 손을 댔다면 저장할 수 있게 열어 둡니다.
            // 기준이 담긴 페이지를 불러오는 순간 정확한 값으로 다시 판단합니다.
            return hasUserInteracted
        }
        return selectedItemImageId != initialSelectedItemImageId
    }

    private(set) var folderId: String

    // Paging
    @Published private(set) var isInitialLoading: Bool = false
    private var isLoading: Bool = false
    private var hasMore: Bool = true
    private var page: Int = 0          // 서버의 data.number (0-based)
    private let pageSize: Int = 10     // 서버의 data.size와 일치

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
                    recordInitialSelectionIfNeeded(with: contents)
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

    /// 다음 페이지를 미리 불러올 거리. 끝에서 이만큼 남으면 요청합니다.
    ///
    /// 한 페이지 분량을 미리 받아 두면, 사용자가 바닥에 닿기 전에 다음 페이지가 도착해
    /// 기다리는 구간이 생기지 않습니다. 안드로이드 Paging 의 기본값과 같은 기준입니다.
    private var prefetchDistance: Int { pageSize }

    /// 다음 페이지 로드
    func loadNextIfNeeded(currentIndex: Int) {
        guard currentIndex >= images.count - prefetchDistance else { return }
        fetchImages()
    }

    /// 현재 적용된 대표 사진을 기준값으로 기록하고, 아직 손대지 않았다면 선택된 상태로 보여 줍니다.
    ///
    /// `selected`는 현재 적용된 이미지 하나에만, 그 이미지가 담긴 페이지에서만 내려옵니다.
    /// 그래서 사용자가 이미 다른 이미지를 고른 뒤에 그 페이지가 도착하더라도
    /// 기준값만큼은 반드시 챙겨 둡니다. 그러지 않으면 원래 사진을 다시 골라도
    /// 기준이 nil로 남아 저장 버튼이 계속 활성화됩니다.
    private func recordInitialSelectionIfNeeded(with contents: [FolderThumbnailImageResponse]) {
        guard !hasFoundInitialSelection,
              let selected = contents.first(where: { $0.selected == true }) else { return }

        initialSelectedItemImageId = selected.itemImageId
        hasFoundInitialSelection = true

        // 사용자가 이미 고른 것이 있다면 그 선택을 덮어쓰지 않습니다.
        guard !hasUserInteracted else { return }
        selectedItemImageId = selected.itemImageId
    }

    // MARK: - 선택

    /// 이미지 선택. 이미 선택된 이미지를 다시 고르면 선택이 해제됩니다.
    func toggleSelection(itemImageId: Int) {
        // 서버가 내려준 선택 상태는 더 이상 덮어쓰지 않습니다.
        hasUserInteracted = true
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
