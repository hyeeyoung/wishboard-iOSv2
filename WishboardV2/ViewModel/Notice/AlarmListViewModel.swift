//
//  NoticeViewModel.swift
//  WishboardV2
//
//  Created by gomin on 8/29/24.
//

import Foundation
import Combine
import Foundation
import WBNetwork

/// 알림 한 건이 아이템 알림인지 시스템 알림인지
enum NoticeCategory {
    case item
    case system
}

struct NoticeItem {
    let id: Int
    let imageUrl: String?
    let notiType: String
    let name: String
    var readState: Bool
    let notiDate: String
    let link: String?

    /// 읽음 처리의 키. 아이템 id 와 다릅니다.
    /// 캘린더 화면처럼 알림 목록이 아닌 곳에서는 비어 있습니다.
    var notificationId: Int? = nil
    var category: NoticeCategory = .item
}

@MainActor
class AlarmListViewModel: ObservableObject {
    @Published var noticeItems: [NoticeItem] = []
    @Published var readState: Bool = false
    /// 알림 리스트 조회 중인지 여부.
    /// 당겨서 새로고침에는 자체 인디케이터가 있어 로딩뷰를 띄우지 않습니다.
    @Published var isLoading: Bool = false

    // Paging
    private var page: Int = 0
    private let pageSize: Int = 10
    private var hasMore: Bool = true
    private var isFetching: Bool = false

    private var cancellables = Set<AnyCancellable>()
    
    init() {
        
    }
    
    // 알림 리스트 조회
    func fetchItems(isRefreshing: Bool = false) {
        fetch(reset: true, isRefreshing: isRefreshing)
    }

    /// 목록 하단 근처에서 호출해 다음 페이지를 불러옵니다.
    func loadNextIfNeeded(currentIndex: Int, threshold: Int = 2) {
        guard currentIndex >= noticeItems.count - threshold else { return }
        fetch(reset: false)
    }

    private func fetch(reset: Bool, isRefreshing: Bool = false) {
        guard !isFetching, reset || hasMore else { return }
        isFetching = true

        if reset {
            page = 0
            hasMore = true
        }

        Task {
            isLoading = !isRefreshing && reset && noticeItems.isEmpty
            defer {
                isLoading = false
                isFetching = false
            }

            do {
                let useCase = GetNotificationsUseCase()
                let response = try await useCase.execute(page: page, size: pageSize)

                let items = (response.data?.content ?? []).map { NoticeItem(from: $0) }

                if reset {
                    noticeItems = items
                } else {
                    // 스크롤 중 새 알림이 생기면 다음 페이지에 한 건이 겹쳐 올 수 있습니다.
                    let existingIds = Set(noticeItems.compactMap { $0.notificationId })
                    noticeItems += items.filter { item in
                        guard let id = item.notificationId else { return true }
                        return !existingIds.contains(id)
                    }
                }

                hasMore = !(response.data?.last ?? true)
                if hasMore { page += 1 }
            } catch {
                if reset { noticeItems = [] }
                throw error
            }
        }
    }
    
    // 알림 셀 탭 > 읽음 처리
    func updateReadState(_ item: NoticeItem) {
        guard let index = noticeItems.firstIndex(where: { $0.notificationId == item.notificationId }),
              !noticeItems[index].readState,
              let notificationId = item.notificationId else { return }

        noticeItems[index].readState = true
        updateReadStateInServer(notificationId: notificationId)
    }
    
    private func updateReadStateInServer(notificationId: Int) {
        Task {
            do {
                let usecase = UpdateReadStateUseCase()
                _ = try await usecase.execute(notificationId: notificationId)
            } catch {
                throw error
            }
        }
    }
}

// MARK: - 응답 → 화면 모델

private extension NoticeItem {
    /// 알림 종류에 따라 보여 줄 값이 달라집니다.
    /// 아이템 알림은 알림 종류와 상품명을, 시스템 알림은 제목과 본문을 씁니다.
    init(from response: NotificationResponse) {
        let category: NoticeCategory = (response.notificationCategory == .system) ? .system : .item

        switch category {
        case .item:
            self.init(id: response.itemId ?? 0,
                      imageUrl: response.itemImages?.first?.itemImageUrl,
                      notiType: response.itemNotificationType ?? "",
                      name: response.itemName ?? "",
                      readState: response.readState ?? false,
                      notiDate: response.displayDate,
                      link: response.itemUrl,
                      notificationId: response.notificationId,
                      category: .item)
        case .system:
            self.init(id: response.notificationId ?? 0,
                      imageUrl: nil,
                      notiType: response.title ?? "",
                      name: response.body ?? "",
                      readState: response.readState ?? false,
                      notiDate: response.displayDate,
                      link: nil,
                      notificationId: response.notificationId,
                      category: .system)
        }
    }
}
