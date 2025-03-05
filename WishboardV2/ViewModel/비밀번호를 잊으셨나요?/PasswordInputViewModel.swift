//
//  PasswordInputViewModel.swift
//  WishboardV2
//
//  Created by gomin on 3/5/25.
//

import Foundation
import Combine

class PasswordInputViewModel {
    // 입력된 값
    @Published var input: String = ""
    
    // 유효성 검사 결과
    @Published var isValidPW: Bool = false
    @Published var isValidCode: Bool = false
    
    // 버튼 활성화 상태
    @Published var isButtonEnabled: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init(type: InputType) {
        switch type {
        case .emailLogin:
            $input
                .map { self.validateCode($0) }
                .sink { [weak self] isValid in
                    self?.isValidCode = isValid
                    self?.isButtonEnabled = isValid
                }
                .store(in: &cancellables)
            break
            
        case .register:
            $input
                .map { self.validatePW($0) }
                .sink { [weak self] isValid in
                    self?.isValidPW = isValid
                    self?.isButtonEnabled = isValid
                }
                .store(in: &cancellables)
            break
        }
        
    }
    
    /// 비밀번호 형식 검증 함수
    private func validatePW(_ password: String) -> Bool {
        let passwordRegex = "^(?=.*[A-Za-z])(?=.*\\d)(?=.*[!@#$%^&*(),.?\":{}|<>]).{8,}$"
        return NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: password)
    }
    
    /// 코드 형식 검증 함수
    private func validateCode(_ code: String) -> Bool {
        return !code.isEmpty
    }
}
