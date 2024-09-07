//
//  ModifyPasswordViewModel.swift
//  WishboardV2
//
//  Created by gomin on 9/7/24.
//

import Foundation
import Combine
import WBNetwork
import Core

final class ModifyPasswordViewModel {
    // Input
    @Published var password: String = ""
    @Published var repeatPassword: String = ""

    // Output
    @Published var isButtonEnabled: Bool = false
    @Published var isPasswordValid: Bool = true
    @Published var isRepeatPwValid: Bool = true
    
    private var cancellables = Set<AnyCancellable>()

    init() {
        // 비밀번호 유효성 검사
        $password
            .sink { [weak self] password in
                guard let self = self else {return}
                self.isPasswordValid = self.isValidPassword(password)
            }
            .store(in: &cancellables)
        
        // 재입력 비밀번호 검사
        $repeatPassword
            .sink { [weak self] repeatPassword in
                guard let self = self else {return}
                self.isRepeatPwValid = self.validateRepeatPassword(repeatPassword)
            }
            .store(in: &cancellables)
        
        Publishers.CombineLatest($password, $repeatPassword)
            .map { [weak self] password, repeatPassword in
                guard let self = self else {return false}
                if password.isEmpty || repeatPassword.isEmpty {return false}
                return self.isValidPassword(password) && self.validateRepeatPassword(repeatPassword)
            }
            .assign(to: \.isButtonEnabled, on: self)
            .store(in: &cancellables)
        
    }
    
    // 비밀번호 유효성 검사
    private func isValidPassword(_ password: String) -> Bool {
        if password.isEmpty {return true}
        guard password.count >= 8 else { return false }
        
        let digitRegex = ".*[0-9]+.*"
        let lowerCaseRegex = ".*[a-z]+.*"
        let upperCaseRegex = ".*[A-Z]+.*"
        let specialCharacterRegex = ".*[!&^%$#@()/]+.*"
        
        let digitTest = NSPredicate(format:"SELF MATCHES %@", digitRegex).evaluate(with: password)
        let lowerCaseTest = NSPredicate(format:"SELF MATCHES %@", lowerCaseRegex).evaluate(with: password)
        let upperCaseTest = NSPredicate(format:"SELF MATCHES %@", upperCaseRegex).evaluate(with: password)
        let specialCharacterTest = NSPredicate(format:"SELF MATCHES %@", specialCharacterRegex).evaluate(with: password)
        
        // 4가지 중 최소 2가지를 포함해야 함
        let validConditions = [digitTest, lowerCaseTest, upperCaseTest, specialCharacterTest]
        let validCount = validConditions.filter { $0 }.count
        
        return validCount >= 2
    }
    
    private func validateRepeatPassword(_ repeatPassword: String) -> Bool {
        if repeatPassword.isEmpty {return true}
        
        return repeatPassword == self.password
    }
    
    // 비밀번호 변경 API Call
    func modifyPassword() async throws {
        do {
            let usecase = ModifyPasswordUseCase()
            _ = try await usecase.execute(password: self.password)
        } catch {
            SnackBar.shared.show(type: .errorMessage)
            throw error
        }
    }
}
