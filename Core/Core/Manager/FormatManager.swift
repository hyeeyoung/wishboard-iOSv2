//
//  FormatManager.swift
//  Core
//
//  Created by gomin on 8/18/24.
//
import Foundation

public final class FormatManager {
    
    public static let shared = FormatManager()
    private init() { }
    
    // MARK: - Date
    // 서버에서 받은 created_at을 "YY년 MM월 dd일 HH:mm"로 변환
    // '0일 전', '0주전' 으로 변환
    public func createdDateToKoreanStr(_ date: String) -> String? {
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        format.locale = Locale(identifier: "ko_KR")

        guard let startTime = format.date(from: date) else {return "?"}
        guard let endTime = format.date(from: Date().toSecondString()) else {return "?"}

        var useTime = Int(endTime.timeIntervalSince(startTime))
        
        return dateToWeek(dateNum: useTime)
    }
    public func dateToWeek(dateNum: Int) -> String {
        if dateNum < 0 {return "방금 전"}
        switch dateNum {
        case 0...59:
            return "방금 전"
        case 60...3600:
            return "\(dateNum / 60)분 전"
        case 3600...86400:
            return "\(dateNum / 3600)시간 전"
        case 86400...604800:
            return "\(dateNum / 86400)일 전"
        case 604800...2592000:
            return "\(dateNum / 604800)주 전"
        case 2592000...31536000:
            return "\(dateNum / 2592000)개월 전"
        default:
            return "\(dateNum / 31536000)년 전"
        }
    }
    // MARK: - 아이템 일반 등록 뷰
    // 상품 알림 설정 후 출력되는 날짜 Text
    public func notiDateToKoreanStr(_ date: String) -> String? {
        let dateToDate = date.toNotiDate() //YYYY-MM-dd HH:mm
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "YY년 MM월 dd일 HH:mm"
        if let dateToDate = dateToDate {
            return dateformatter.string(from: dateToDate)
        } else {return nil}
    }
    // MARK: - 아이템 상세 뷰
    // 서버에서 받은 notification_date를 변환
    // YYYY-MM-dd HH:mm -> YY년 MM월 dd일 HH:mm
    /*
     - 디데이 경과 전 : D-n
     - 디데이 경과까지 24시간 미만 남은 경우 : 내일 x시 y분
         - x는 24시간제, 0-9시는 한자리수로 표현, y는 0분이라면 포기하지 않음
     - 디데이 당일 : 오늘 x시 y분
         - x는 24시간제, 0-9시는 한자리수로 표현, y는 0분이라면 포기하지 않음
     - 디데이 경과 후 : 21년 a월 b일
         - a, b 모두 1-9는 한자리 수로 표기해 주세요!
     */
    public func showNotificationDateInItemDetail(_ date: String) -> String? {
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm"
        format.locale = Locale(identifier: "ko_KR")

        guard let targetDate = format.date(from: date) else { return "?" }

        let now = Date()
        let calendar = Calendar.current

        // day 차이만 따로 계산!
        let dayDiff = calendar.dateComponents([.day], from: now.startOfDay(), to: targetDate.startOfDay()).day ?? 0

        switch dayDiff {
        case 0:
            // D-0: 오늘이면 시간까지 보여줌
            return "오늘 \(formatHourMinute(from: targetDate))"
        case 1:
            return "내일 \(formatHourMinute(from: targetDate))"
        case 2...:
            return "D-\(dayDiff)"
        default:
            // 지난 날짜
            let pastFormatter = DateFormatter()
            pastFormatter.dateFormat = "YY년 MM월 dd일"
            return pastFormatter.string(from: targetDate)
        }
    }
    private func formatHourMinute(from date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)

        let hour = components.hour ?? 0
        let minute = components.minute ?? 0

        return minute == 0 ? "\(hour)시" : "\(hour)시 \(minute)분"
    }
    
    // "YY년 MM월 dd일 HH:mm"을 "YYYY-MM-dd HH:mm:ss"로 변환
    // 2022-9-20 1:30
    public func koreanStrToDate(_ str: String) -> String? {
//        print("원래 날짜:", str)
        let strToDate = str.koreanToDate()
//        print("Date 변환 최종:", strToDate?.toString())
        if let strToDate = strToDate {
            return strToDate.toString()
        } else {return nil}
    }
    
    // 14:30 을 '오후 2시 30분'으로 변환
    public func convertTimeToKoreanFormat(hour: String, minute: String) -> String {
        let timeString = "\(hour):\(minute)"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        
        guard let date = formatter.date(from: timeString) else {
            return timeString
        }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let isZeroMinute = (components.minute == 0)

        formatter.dateFormat = isZeroMinute ? "a h시" : "a h시 m분"
        return formatter.string(from: date)
    }
    
    // "25년 07월 17일" -> "25.7.17" 로 변환
    public func convertKoreanDateToShortFormat(_ input: String) -> String {
        // "25년 07월 17일"
        let components = input
            .replacingOccurrences(of: "년", with: "")
            .replacingOccurrences(of: "월", with: "")
            .replacingOccurrences(of: "일", with: "")
            .split(separator: " ")
        
        guard components.count == 3,
              let year = Int(components[0]),
              let month = Int(components[1]),
              let day = Int(components[2]) else {
            return input  // fallback
        }
        
        return "\(year).\(month).\(day)"
    }
    // MARK: - Number (price)
    /// 숫자를 ,넣은 문자열로     // 1000 -> 1,000
    public func numToPrice(num: Int) -> String? {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        
        if let price = numberFormatter.string(from: NSNumber(value: num)) {
            return price
        } else {
            return nil
        }
    }
    /// 숫자문자열을 ,넣은 문자열로
    public func strToPrice(numStr: String) -> String? {
        if let num = Int(numStr) {return self.numToPrice(num: num)}
        else {return nil}
    }
    /// 문자열을 숫자문자열로     // ₩ 1,000 -> 1000
    public func priceToStr(price: String) -> String {
        let priceStr = price.replacingOccurrences(of: "[₩,\\s]", with: "", options: .regularExpression)
        return priceStr
    }
}
// MARK: - String extension
extension String {
    public func toCreatedDate() -> Date? { //"yyyy-MM-dd HH:mm:ss"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "ko_KR")
        if let date = dateFormatter.date(from: self) {
            return date
        } else {
            return nil
        }
    }
    public func toNotiDate() -> Date? { //"yyyy-MM-dd HH:mm"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        dateFormatter.timeZone = TimeZone(identifier: "ko_KR")
        if let date = dateFormatter.date(from: self) {
            return date
        } else {
            return nil
        }
    }
    public func koreanToDate() -> Date? {
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "YY년 MM월 dd일 HH:mm"
        dateformatter.timeZone = TimeZone(identifier: "ko_KR")
        if let date = dateformatter.date(from: self) {
//            print("Date 변환 날짜:", date)
            return date
        } else {
//            print("Date 변환 x")
            return nil
        }
    }
}
// MARK: - Date extension
extension Date {
    public func toString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        dateFormatter.timeZone = TimeZone(identifier: "ko_KR")
        return dateFormatter.string(from: self)
    }
    public func toSecondString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "ko_KR")
        return dateFormatter.string(from: self)
    }
    func startOfDay() -> Date {
        return Calendar.current.startOfDay(for: self)
    }
}
