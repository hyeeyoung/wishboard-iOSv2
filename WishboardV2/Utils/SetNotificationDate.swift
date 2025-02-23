//
//  SetNotificationDate.swift
//  WishboardV2
//
//  Created by gomin on 2/23/25.
//

import Foundation

struct SetNotificationDate {
    static let notificationData = ["재입고", "오픈", "프리오더", "세일 시작", "세일 마감", "리마인드"]
    
    static let dateData: [String] = generateDateData()
    static let hourData: [String] = (0...23).map { String(format: "%02d", $0) }
    static let minuteData: [String] = ["00", "30"]
    
    static let currentYear: String = getCurrentDateComponent(.year)
    static let currentMonth: String = getCurrentDateComponent(.month)
    static let currentDay: String = getCurrentDateComponent(.day)
    static let currentHour: String = getCurrentDateComponent(.hour)
    static let currentMinute: String = adjustCurrentMinute()

    // MARK: - 현재 날짜 컴포넌트 가져오기
    private static func getCurrentDateComponent(_ component: Calendar.Component) -> String {
        let date = Date()
        let calendar = Calendar.current
        let value = calendar.component(component, from: date)
        return String(format: "%02d", value % 100) // 연도는 뒤 2자리만
    }
    
    // MARK: - 현재 분 보정 (00 또는 30)
    private static func adjustCurrentMinute() -> String {
        let minute = Int(getCurrentDateComponent(.minute)) ?? 0
        return minute < 30 ? "30" : "00"
    }

    // MARK: - +90일 날짜 리스트 생성
    private static func generateDateData() -> [String] {
        var dates: [String] = []
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yy년 MM월 dd일"
        
        for i in 0...90 {
            if let newDate = calendar.date(byAdding: .day, value: i, to: Date()) {
                dates.append(dateFormatter.string(from: newDate))
            }
        }
        return dates
    }
}
