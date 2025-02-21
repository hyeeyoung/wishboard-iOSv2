//
//  CalendarViewModel.swift
//  WishboardV2
//
//  Created by gomin on 9/7/24.
//

import Foundation
import Combine

struct CalendarItem {
    let id: Int
    let imageUrl: String
    let notiType: String
    let name: String
    let notiDate: String
}

final class CalendarViewModel {
    // Input
    @Published var selectedDate: Date = Date()
    
    // Output
    @Published var notificationItems: [CalendarItem] = [] // 선택된 날짜의 알림 일정
    @Published var highlightedDates: [CalendarItem] = [] // 알림이 있는 날짜 목록

    init() {
        fetchHighlightedDates()
    }

    // 서버에서 알림이 있는 날짜 가져오기 (Mock 데이터)
    public func fetchHighlightedDates() {
        let mockData = [
            CalendarItem(id: 1, imageUrl: "", notiType: "", name: "item1", notiDate: "2024-09-02 10:00"),
            CalendarItem(id: 2, imageUrl: "", notiType: "", name: "item2", notiDate: "2024-09-02 10:00"),
            CalendarItem(id: 3, imageUrl: "", notiType: "", name: "item3", notiDate: "2024-09-03 10:00"),
            CalendarItem(id: 4, imageUrl: "", notiType: "", name: "item4", notiDate: "2024-09-04 10:00"),
        ]
        self.highlightedDates = mockData
    }

    // 특정 날짜에 대한 알림 일정 가져오기
    func fetchNotifications(for date: Date) {
        // 서버 통신으로 해당 날짜의 알림 일정 가져오는 코드 (Mock 예시)
        let filteredItems = highlightedDates.filter { Calendar.current.isDate($0.notiDate.toNotiDate() ?? Date(), inSameDayAs: date) }
        self.notificationItems = filteredItems
    }
}
