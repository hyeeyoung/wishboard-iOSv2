//
//  CalendarViewModel.swift
//  WishboardV2
//
//  Created by gomin on 9/7/24.
//

import Foundation
import Combine

class CalendarViewModel: ObservableObject {
    @Published var currentMonth: Date = Date() // 현재 표시 중인 달
    @Published var alarms: [Date: [NoticeItem]] = [:] // 날짜별 알람 데이터
    @Published var selectedDate: Date? = nil // 선택된 날짜
    @Published var selectedAlarms: [NoticeItem] = [] // 선택한 날짜의 알람 리스트
    @Published var days: [Date?] = [] // 달력에 표시할 날짜 리스트
    
    private var cancellables = Set<AnyCancellable>()

    init() {
        fetchAlarms()
    }
    
    // 🛠 API 호출 (모든 알람 가져오기)
    func fetchAlarms() {
        // 예시: 서버에서 데이터 가져오는 API (비동기 처리)
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            let dummyAlarms = [
                NoticeItem(id: 0, imageUrl: "", notiType: "재입고", name: "회의 알람", readState: true, notiDate: "2025-03-18 13:13:13", link: nil)
            ]
            
            DispatchQueue.main.async {
                self.alarms = self.processAlarms(dummyAlarms)
            }
        }
    }

    // 🛠 서버에서 가져온 알람 데이터를 날짜별 Dictionary로 변환
    private func processAlarms(_ alarms: [NoticeItem]) -> [Date: [NoticeItem]] {
        var alarmDict: [Date: [NoticeItem]] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        for alarm in alarms {
            if let date = dateFormatter.date(from: alarm.notiDate) {
                alarmDict[date, default: []].append(alarm)
            }
        }
        return alarmDict
    }
    
    // 🛠 이전 달 이동
    func moveToPreviousMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth)!
    }
    
    // 🛠 다음 달 이동
    func moveToNextMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth)!
    }
    
    func updateCalendarDays() {
        let calendar = Calendar(identifier: .gregorian)
        var components = calendar.dateComponents([.year, .month], from: currentMonth)
        components.day = 1

        guard let firstDayOfMonth = calendar.date(from: components) else { return }

        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) // 일요일 = 1, 월요일 = 2, ..., 토요일 = 7

        let daysToSubtract = firstWeekday - 1
        let startDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: firstDayOfMonth)!

        days = (0..<42).map { calendar.date(byAdding: .day, value: $0, to: startDate) }
    }
    
    func selectDate(_ date: Date) {
        selectedDate = date
        selectedAlarms = alarms[date] ?? []
    }
}
