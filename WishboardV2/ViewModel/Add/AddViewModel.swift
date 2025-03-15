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
            let itemPrice = self.itemPrice
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
            SnackBar.shared.show(type: .errorMessage)
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
            let itemPrice = self.itemPrice
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
            SnackBar.shared.show(type: .errorMessage)
            if let moyaError = error as? MoyaError, let response = moyaError.response {
                if response.statusCode == 400 {
                    print("400 error")
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
    
    private func convertDateFormat(input: String) -> String? {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yy년 MM월 dd일 HH:mm"
        inputFormatter.locale = Locale(identifier: "ko_KR") // 한글 형식 대응

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        if let date = inputFormatter.date(from: input) {
            return outputFormatter.string(from: date)
        } else {
            return nil
        }
    }
}
