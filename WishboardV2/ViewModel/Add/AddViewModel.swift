//
//  AddViewModel.swift
//  WishboardV2
//
//  Created by gomin on 2/22/25.
//

import Foundation
import UIKit
import Combine

final class AddViewModel {
    // 입력 데이터
    @Published var itemName: String = ""
    @Published var itemPrice: String = ""
    @Published var selectedFolder: String? = nil
    @Published var selectedAlarm: String? = nil
    @Published var selectedLink: String? = nil
    @Published var memo: String = ""
    @Published var selectedImage: UIImage? = nil
    
    // 저장 버튼 활성화 여부
    var isSaveEnabled: AnyPublisher<Bool, Never> {
        return Publishers.CombineLatest(itemNamePublisher, itemPricePublisher)
            .map { !$0.isEmpty && !$1.isEmpty }
            .eraseToAnyPublisher()
    }
    
    // 입력값 검증
    private var itemNamePublisher: AnyPublisher<String, Never> {
        $itemName.eraseToAnyPublisher()
    }
    
    private var itemPricePublisher: AnyPublisher<String, Never> {
        $itemPrice.eraseToAnyPublisher()
    }
    
    // 가격 포맷 (콤마 추가)
    func formatPrice(_ text: String) -> String {
        let filtered = text.filter { "0123456789".contains($0) }
        guard let number = Int(filtered) else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? ""
    }
    
    // API 호출 (더미)
    func saveItem(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            completion(true) // 성공 시 true 반환
        }
    }
}
