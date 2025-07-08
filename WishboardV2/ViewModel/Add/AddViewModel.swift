//
//  AddViewModel.swift
//  WishboardV2
//
//  Created by gomin on 2/22/25.
//

import Foundation
import UIKit
import Combine
import WBNetwork
import Moya
import Core

final class AddViewModel {
    // 입력 데이터
    @Published var selectedImage: UIImage? = nil
    @Published var itemName: String = ""
    @Published var itemPrice: String = ""
    @Published var selectedFolderId: Int? = nil
    @Published var selectedAlarmType: String? = nil
    @Published var selectedAlarmDate: String? = nil
    @Published var selectedLink: String? = nil
    @Published var memo: String? = nil
    
    @Published var selectedAlarm: String? = nil
    @Published var selectedFolder: String? = nil
    @Published var folders: [FolderListResponse] = []
    
    // 저장 버튼 활성화 여부
    var isSaveEnabled: AnyPublisher<Bool, Never> {
        return Publishers.CombineLatest3(itemNamePublisher, itemPricePublisher, selectedImagePublisher)
            .map { !$0.isEmpty && !$1.isEmpty && $2 != nil }
            .eraseToAnyPublisher()
    }
    
    // 입력값 검증
    private var itemNamePublisher: AnyPublisher<String, Never> {
        $itemName.eraseToAnyPublisher()
    }
    
    private var itemPricePublisher: AnyPublisher<String, Never> {
        $itemPrice.eraseToAnyPublisher()
    }
    
    private var selectedImagePublisher: AnyPublisher<UIImage?, Never> {
        $selectedImage.eraseToAnyPublisher()
    }
    
    // 가격 포맷 (콤마 추가)
    func formatPrice(_ text: String) -> String {
        let filtered = text.filter { "0123456789".contains($0) }
        guard let number = Int(filtered) else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? ""
    }
    
    // API 호출
    func addItem() async throws {
        do {
            
            let itemName = self.itemName
            let itemPrice = FormatManager.shared.priceToStr(price: self.itemPrice)
            let selectedFolderId = self.selectedFolderId
            let itemImage = self.selectedImage?.resizeImageIfNeeded().jpegData(compressionQuality: 1.0)
            let itemURL = self.selectedLink
            let itemMemo = self.memo
            let notiType = self.selectedAlarmType
            let notiDate = self.convertDateFormat(input: self.selectedAlarmDate ?? "")
            
            let item = RequestItemDTO(folderId: selectedFolderId,
                                         photo: itemImage,
                                         itemName: itemName,
                                         itemPrice: itemPrice,
                                         itemURL: itemURL,
                                         itemMemo: itemMemo,
                                         itemNotificationType: notiType, itemNotificationDate: notiDate)
            
            let usecase = AddItemUseCase()
            _ = try await usecase.execute(type: .manual, item: item)
        } catch {
            if let moyaError = error as? MoyaError, let response = moyaError.response {
                if response.statusCode == 400 {
                    print("400 error")
//                    SnackBar.shared.show(type: .errorMessage)
                }
            }
            throw error
        }
    }
    
    func modifyItem(idx: Int) async throws {
        do {
            
            let itemName = self.itemName
            let itemPrice = FormatManager.shared.priceToStr(price: self.itemPrice)
            let selectedFolderId = self.selectedFolderId
            let itemImage = self.selectedImage?.resizeImageIfNeeded().jpegData(compressionQuality: 1.0)
            let itemURL = self.selectedLink
            let itemMemo = self.memo
            let notiType = self.selectedAlarmType
            let notiDate = self.convertDateFormat(input: self.selectedAlarmDate ?? "")
            
            let item = RequestItemDTO(folderId: selectedFolderId,
                                         photo: itemImage,
                                         itemName: itemName,
                                         itemPrice: itemPrice,
                                         itemURL: itemURL,
                                         itemMemo: itemMemo,
                                         itemNotificationType: notiType, itemNotificationDate: notiDate)
            
            let usecase = ModifyItemUseCase()
            _ = try await usecase.execute(idx: idx, item: item)
        } catch {
//            SnackBar.shared.show(type: .errorMessage)
            if let moyaError = error as? MoyaError, let response = moyaError.response {
                if response.statusCode == 400 {
//                    SnackBar.shared.show(type: .errorMessage)
                }
            }
            throw error
        }
    }
    
    // 폴더 데이터 가져오기
    func fetchFolders() {
        _Concurrency.Task {
            do {
                let usecase = GetFolderListUseCase()
                let data = try await usecase.execute()
                
                DispatchQueue.main.async {
                    self.folders = data
                }
            } catch {
                throw error
            }
        }
    }
    
    private func convertDateFormat(input: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yy년 MM월 dd일 HH:mm"
        inputFormatter.locale = Locale(identifier: "ko_KR") // 한글 형식 대응

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        if let date = inputFormatter.date(from: input) {
            return outputFormatter.string(from: date)
        } else {
            return input
        }
    }
    
    func convertKoreanShortDateTimeToFullFormat(_ input: String) -> String? {
        // 예: "26.7.14 오후 3시 30분"
        let pattern = #"(\d{2})\.(\d{1,2})\.(\d{1,2})\s+(오전|오후)\s+(\d{1,2})시(?:\s+(\d{1,2})분)?"#
        let regex = try! NSRegularExpression(pattern: pattern)

        guard let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)) else {
            return nil
        }

        func group(_ i: Int) -> String? {
            guard let range = Range(match.range(at: i), in: input) else { return nil }
            return String(input[range])
        }

        guard let yearStr = group(1),
              let monthStr = group(2),
              let dayStr = group(3),
              let ampm = group(4),
              let hourStr = group(5) else {
            return nil
        }

        let minuteStr = group(6) ?? "0"

        guard let year = Int(yearStr),
              let month = Int(monthStr),
              let day = Int(dayStr),
              var hour = Int(hourStr),
              let minute = Int(minuteStr) else {
            return nil
        }

        // 오후면 12 더해줌 (단, 12시는 그대로)
        if ampm == "오후", hour < 12 {
            hour += 12
        } else if ampm == "오전", hour == 12 {
            hour = 0
        }

        var components = DateComponents()
        components.year = 2000 + year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0

        let calendar = Calendar(identifier: .gregorian)
        guard let date = calendar.date(from: components) else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}
