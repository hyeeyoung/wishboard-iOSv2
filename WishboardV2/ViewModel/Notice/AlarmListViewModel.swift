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

struct NoticeItem {
    let id: Int
    let imageUrl: String?
    let notiType: String
    let name: String
    var readState: Bool
    let notiDate: String
    let link: String?
}

@MainActor
class AlarmListViewModel: ObservableObject {
    @Published var noticeItems: [NoticeItem] = []
    @Published var readState: Bool = false
    /// 알림 리스트 조회 중인지 여부.
    /// 당겨서 새로고침에는 자체 인디케이터가 있어 로딩뷰를 띄우지 않습니다.
    @Published var isLoading: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        
    }
    
    // 알림 리스트 조회
    func fetchItems(isRefreshing: Bool = false) {
        Task {
            isLoading = !isRefreshing
            defer { isLoading = false }

            do {
                let useCase = GetNoticesUseCase()
                let datas = try await useCase.execute()
                
                var items: [NoticeItem] = []
                for data in datas {
                    let item = NoticeItem(id: data.id ?? 0,
                                          imageUrl: data.itemImages?.first?.itemImageUrl ?? "",
                                          notiType: data.itemNotificationType ?? "",
                                          name: data.itemName ?? "",
                                          readState: data.readState ?? false,
                                          notiDate: data.itemNotificationDate ?? "",
                                          link: data.itemUrl)
                    
                    items.append(item)
                }
                self.noticeItems = items
            } catch {
                throw error
            }
        }
    }
    
    // 알림 셀 탭 > 읽음 처리
    func updateReadState(_ item: NoticeItem) {
        if let index = noticeItems.firstIndex(where: { $0.id == item.id }) {
            if !(noticeItems[index].readState) {
                noticeItems[index].readState = true
                updateReadStateInServer(item: item)
            }
        }
    }
    
    private func updateReadStateInServer(item: NoticeItem) {
        Task {
            do {
                let usecase = UpdateStateUseCase()
                let data = try await usecase.execute(itemId: String(item.id))
            } catch {
                throw error
            }
        }
    }
}
