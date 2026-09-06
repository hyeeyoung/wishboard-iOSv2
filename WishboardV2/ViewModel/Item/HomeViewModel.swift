//
//  HomeViewModel.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation
import Combine
import WBNetwork

final class HomeViewModel {
    @Published var items: [WishListResponse] = []
    @Published var displayedItems: [WishListResponse] = []
    @Published var totalCount: Int = 0
    @Published var ownedCount: Int = 0
    @Published var isExcludingOwned: Bool = false
    @Published var hasOwnedItems: Bool = false

    // Paging
    @Published var isLoading: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var hasMore: Bool = true
    private var page: Int = 0
    private let pageSize: Int = 10
    private var cancellables = Set<AnyCancellable>()

    init() {
        // 서버에서 필터링된 결과를 받아오지만, 클라이언트 로컬 상태 변경(소장 등록 등)도 반영
        Publishers.CombineLatest($items, $isExcludingOwned)
            .map { items, isExcluding in
                isExcluding ? items.filter { $0.itemStatus != .owned } : items
            }
            .assign(to: &$displayedItems)

        $ownedCount
            .map { $0 > 0 }
            .assign(to: &$hasOwnedItems)
    }

    func toggleExcludeOwned() {
        isExcludingOwned.toggle()
        fetchItems(reset: true)
    }

    /// 최초 로드 or 다음 페이지 로드
    func fetchItems(reset: Bool = false) {
        guard !isLoading, hasMore || reset else { return }
        isLoading = true

        if reset {
            page = 0
            hasMore = true
        }

        let itemStatus: ItemStatusType? = isExcludingOwned ? .wish : nil

        Task {
            do {
                let usecase = GetWishItemsUseCase()
                let response = try await usecase.execute(page: page, size: pageSize, itemStatus: itemStatus)

                if reset {
                    items.removeAll()
                    await fetchItemCounts()
                }

                if let itemDatas = response.data?.content {
                    items.append(contentsOf: itemDatas)
                }

                hasMore = !(response.data?.last ?? true)
                if hasMore {
                    page += 1
                }

                isLoading = false
                isRefreshing = false
            } catch {
                if reset { items = [] }
                isLoading = false
                isRefreshing = false
            }
        }
    }

    func fetchItemCounts() async {
        do {
            let usecase = GetItemCountsUseCase()
            let response = try await usecase.execute()
            totalCount = response.data?.totalCount ?? 0
            ownedCount = response.data?.ownedCount ?? 0
        } catch {
            // counts 실패 시 기존 값 유지
        }
    }

    /// 풀-투-리프레시에서 호출
    func refresh() {
        isRefreshing = true
        fetchItems(reset: true)
    }

    /// UICollectionView 스크롤 하단 근처에서 호출해 다음 페이지 로드
    func loadNextIfNeeded(currentIndex: Int, threshold: Int = 2) {
        guard currentIndex >= items.count - threshold else { return }
        fetchItems()
    }
}
