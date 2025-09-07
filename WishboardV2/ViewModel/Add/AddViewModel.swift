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
    @Published var selectedImages: [UIImage] = []
    @Published var itemName: String = ""
    @Published var itemPrice: String = ""
    @Published var selectedFolderId: Int? = nil
    @Published var selectedAlarmType: String? = nil
    @Published var selectedAlarmDate: String? = nil
    @Published var selectedLink: String? = nil
    @Published var memo: String? = nil
    @Published var version: Int? = nil
    @Published var imageChanged: Bool? = false
    
    @Published var selectedAlarm: String? = nil
    @Published var folders: [FolderListResponse] = []
    
    // Paging
    @Published var isLoading: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var hasMore: Bool = true
    private var page: Int = 0          // 서버의 data.number (0-based)
    private let pageSize: Int = 10     // 서버의 data.size와 일치
    
    // 저장 버튼 활성화 여부
    var isSaveEnabled: AnyPublisher<Bool, Never> {
        return Publishers.CombineLatest3(itemNamePublisher, itemPricePublisher, selectedImagePublisher)
            .map { !$0.isEmpty && !$1.isEmpty && !$2.isEmpty }
            .eraseToAnyPublisher()
    }
    
    // 입력값 검증
    private var itemNamePublisher: AnyPublisher<String, Never> {
        $itemName.eraseToAnyPublisher()
    }
    
    private var itemPricePublisher: AnyPublisher<String, Never> {
        $itemPrice.eraseToAnyPublisher()
    }
    
    private var selectedImagePublisher: AnyPublisher<[UIImage], Never> {
        $selectedImages.eraseToAnyPublisher()
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
            let itemImages: [Data]? = self.selectedImages.map { $0.resizeImageIfNeeded().jpegData(compressionQuality: 1.0) ?? Data() }
            let itemURL = self.selectedLink
            let itemMemo = self.memo
            let notiType = self.convertNotiTypeToEnum(input: self.selectedAlarmType)
            let notiDate = self.convertKoreanShortDateTimeToFullFormat(self.selectedAlarmDate ?? "")
              
            let item = RequestItemDTO(folderId: selectedFolderId,
                                      photos: itemImages,
                                      itemName: itemName,
                                      itemPrice: itemPrice,
                                      itemURL: itemURL,
                                      itemMemo: itemMemo,
                                      itemNotificationType: notiType,
                                      itemNotificationDate: notiDate)
            
            let usecase = AddItemUseCase()
            _ = try await usecase.execute(type: .manual, item: item)
        } catch {
            throw error
        }
    }
    
    func modifyItem(idx: Int) async throws {
        do {
            let itemName = self.itemName
            let itemPrice = FormatManager.shared.priceToStr(price: self.itemPrice)
            let selectedFolderId = self.selectedFolderId
            let itemImages: [Data]? = self.selectedImages.map { $0.resizeImageIfNeeded().jpegData(compressionQuality: 1.0) ?? Data() }
            let itemURL = self.selectedLink
            let itemMemo = self.memo
            let notiType = self.convertNotiTypeToEnum(input: self.selectedAlarmType)
            let notiDate = self.convertKoreanShortDateTimeToFullFormat(self.selectedAlarmDate ?? "")
            guard let version = self.version, let imageChanged = self.imageChanged else { return }
            
            let item = RequestItemDTO(folderId: selectedFolderId,
                                      photos: itemImages,
                                      itemName: itemName,
                                      itemPrice: itemPrice,
                                      itemURL: itemURL,
                                      itemMemo: itemMemo,
                                      itemNotificationType: notiType,
                                      itemNotificationDate: notiDate,
                                      version: version,
                                      imageChanged: imageChanged)
            
            let usecase = ModifyItemUseCase()
            _ = try await usecase.execute(idx: idx, item: item)
        } catch {
            throw error
        }
    }
    
    // 폴더 데이터 가져오기
    /// 폴더 가져오기
    func fetchFolders(reset: Bool = false) async throws {
        guard !isLoading, hasMore || reset else { return }
        isLoading = true

        if reset {
            page = 0
            hasMore = true
        }
        do {
            let usecase = GetFoldersUseCase()
            let response = try await usecase.execute(page: page, size: pageSize)

            if reset { folders.removeAll() }

            if let itemDatas = response.data?.content {
                folders.append(contentsOf: itemDatas)
            }

            // 다음 페이지 여부 및 page 증가
            hasMore = !(response.data?.last ?? true)
            if hasMore {
                page += 1
            }

            isLoading = false
            isRefreshing = false
        } catch {
            if reset { folders = [] }
            isLoading = false
            isRefreshing = false
            // 필요하면 에러 상태 @Published 추가해서 바인딩
        }
    }

    /// UICollectionView 스크롤 하단 근처에서 호출해 다음 페이지 로드
    func loadNextIfNeeded(currentIndex: Int, threshold: Int = 2) {
        guard currentIndex >= folders.count - threshold else { return }
        _Concurrency.Task { [weak self] in
            try await self?.fetchFolders()
        }
    }
    
    // 새 폴더 추가
    func addFolder(name: String) async throws {
        do {
            let usecase = AddFolderNameUseCase()
            let _ = try await usecase.execute(folderName: name)
            
            try await self.fetchFolders(reset: true)
            
            DispatchQueue.main.async {
                SnackBar.shared.show(type: .addFolder)
            }
        } catch {
            throw error
        }
    }
    
    /// 선택된 알림 종류를 Enum으로 변환
    private func convertNotiTypeToEnum(input: String?) -> String? {
        if let input = input, let apiValue = Alarm.apiString(from: input) {
            return apiValue
        } else {
            return nil
        }
    }
    
    /// 선택된 알림 날짜 스트링을 포맷팅
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
    
    func formatToShortDate(_ input: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        guard let date = formatter.date(from: input) else {
            return input
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale(identifier: "ko_KR")
        outputFormatter.dateFormat = "yy.M.d"  // ✨ 앞자리 0 생략
        
        return outputFormatter.string(from: date)
    }
}
