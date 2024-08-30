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
    let imageUrl: String
    let notiType: String
    let name: String
    var readState: Bool
    let notiDate: String
    let link: String?
}

@MainActor
class NoticeViewModel: ObservableObject {
    @Published var noticeItems: [NoticeItem] = []
    @Published var readState: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        
    }
    
    // 알림 리스트 조회
    func fetchItems() {
        Task {
            do {
                let useCase = GetNoticesUseCase()
                let datas = try await useCase.execute()
                
                var items: [NoticeItem] = []
                for data in datas {
                    let item = NoticeItem(id: data.item_id ?? 0,
                                          imageUrl: data.item_img_url ?? "",
                                          notiType: data.item_notification_type ?? "",
                                          name: data.item_name ?? "",
                                          readState: ((data.read_state ?? 0) != 0),
                                          notiDate: data.item_notification_date ?? "",
                                          link: data.item_url)
                    
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
