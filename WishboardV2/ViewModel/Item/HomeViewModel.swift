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
    
    // Paging
    @Published var isLoading: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var hasMore: Bool = true
    private var page: Int = 0          // 서버의 data.number (0-based)
    private let pageSize: Int = 10     // 서버의 data.size와 일치
    private var cancellables = Set<AnyCancellable>()
    
    /// 최초 로드 or 다음 페이지 로드
    func fetchItems(reset: Bool = false) {
        guard !isLoading, hasMore || reset else { return }
        isLoading = true

        if reset {
            page = 0
            hasMore = true
        }

        Task {
            do {
                let usecase = GetWishItemsUseCase()
                let response = try await usecase.execute(page: page, size: pageSize)

                if reset { items.removeAll() }

                if let itemDatas = response.data?.content {
                    items.append(contentsOf: itemDatas)
                }

                // 다음 페이지 여부 및 page 증가
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
                // 필요하면 에러 상태 @Published 추가해서 바인딩
            }
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
