//
//  FolderDetailViewModel.swift
//  WishboardV2
//
//  Created by gomin on 8/25/24.
//

import Foundation
import Combine
import WBNetwork
import Moya

final class FolderDetailViewModel {
    
    @Published var items: [WishListResponse] = []
    /// '소장템 제외' 필터가 적용된, 실제로 화면에 노출되는 아이템
    @Published var displayedItems: [WishListResponse] = []
    @Published var isExcludingOwned: Bool = false
    /// 서버가 내려주는 전체 아이템 개수 ('소장템 제외' 필터가 적용된 기준)
    @Published var totalCount: Int = 0
    private(set) var folderId: String
    private var cancellables = Set<AnyCancellable>()
    
    // Paging
    @Published var isLoading: Bool = false
    @Published var isRefreshing: Bool = false
    /// 첫 조회(또는 목록 갱신) 중인지 여부.
    /// 페이지 추가 로드나 당겨서 새로고침에는 로딩뷰를 띄우지 않습니다.
    @Published var isInitialLoading: Bool = false
    @Published var hasMore: Bool = true
    private var page: Int = 0          // 서버의 data.number (0-based)
    private let pageSize: Int = 10     // 서버의 data.size와 일치
    
    init(folderId: String) {
        self.folderId = folderId

        // 서버에서 필터링된 결과를 받아오지만, 클라이언트 로컬 상태 변경(소장 등록 등)도 반영
        Publishers.CombineLatest($items, $isExcludingOwned)
            .map { items, isExcluding in
                isExcluding ? items.filter { $0.itemStatus != .owned } : items
            }
            .assign(to: &$displayedItems)
    }

    func toggleExcludeOwned() {
        isExcludingOwned.toggle()
        fetchItems(reset: true)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 폴더의 아이템들 가져오기
    func fetchItems(reset: Bool = false) {
        guard !isLoading, hasMore || reset else { return }
        isLoading = true
        // 이미 보여 줄 목록이 있다면 로딩뷰를 띄우지 않습니다.
        // 화면에 목록이 그려진 상태에서 로딩뷰가 덮였다 사라지면 깜빡이기 때문입니다.
        isInitialLoading = reset && !isRefreshing && items.isEmpty

        if reset {
            page = 0
            hasMore = true
        }

        let itemStatus: ItemStatusType? = isExcludingOwned ? .wish : nil

        _Concurrency.Task {
            do {
                let usecase = GetFolderItemListUseCase()
                let response = try await usecase.execute(folderId: folderId, page: page, size: pageSize, itemStatus: itemStatus)

                if reset { items.removeAll() }

                totalCount = response.data?.totalElements ?? 0

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
                isInitialLoading = false
            } catch {
                if reset {
                    items = []
                    totalCount = 0
                }
                isLoading = false
                isRefreshing = false
                isInitialLoading = false
                
                if let moyaError = error as? MoyaError, let response = moyaError.response {
                    if response.statusCode == 404 {
                        self.items = []
                        self.totalCount = 0
                    }
                }
            }
        }
    }

    /// 선택한 아이템 일괄 삭제
    func deleteItems(request: BulkDeleteItemsRequest) async throws {
        let usecase = DeleteItemsBulkUseCase()
        _ = try await usecase.execute(request: request)
    }

    /// 풀-투-리프레시에서 호출
    func refresh() {
        // 이미 조회 중이라면 새로고침 상태만 남아 이후 조회에서 로딩뷰가 빠질 수 있어, 그대로 흘려보냅니다.
        guard !isLoading else { return }
        isRefreshing = true
        fetchItems(reset: true)
    }

    /// UICollectionView 스크롤 하단 근처에서 호출해 다음 페이지 로드
    func loadNextIfNeeded(currentIndex: Int, threshold: Int = 2) {
        guard currentIndex >= items.count - threshold else { return }
        fetchItems()
    }
}
