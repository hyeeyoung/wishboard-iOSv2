//
//  EmailInputViewModel.swift
//  WishboardV2
//
//  Created by gomin on 3/4/25.
//

import Foundation
import Combine

class EmailInputViewModel {
    // 입력된 이메일
    @Published var email: String = ""
    
    // 이메일 유효성 검사 결과
    @Published var isValidEmail: Bool = false
    
    // 버튼 활성화 상태
    @Published var isButtonEnabled: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 이메일 유효성 검사 로직
        $email
            .map { self.validateEmail($0) }
            .sink { [weak self] isValid in
                self?.isValidEmail = isValid
                self?.isButtonEnabled = isValid
            }
            .store(in: &cancellables)
    }
    
    /// 이메일 형식 검증 함수
    private func validateEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
}
