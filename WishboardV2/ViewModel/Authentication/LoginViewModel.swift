//
//  LoginViewModel.swift
//  WishboardV2
//
//  Created by gomin on 8/12/24.
//

import Foundation
import Combine
import WBNetwork
import Core

final class LoginViewModel {
    // Input
    @Published var email: String = ""
    @Published var password: String = ""

    // Output
    @Published var isLoginButtonEnabled: Bool = false
    
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Combine을 사용하여 email과 password의 유효성을 검사하고, 조건이 충족되면 로그인 버튼을 활성화
        Publishers.CombineLatest($email, $password)
            .map { [weak self] email, password in
                return self?.isValidEmail(email) == true && self?.isValidPassword(password) == true
            }
            .assign(to: \.isLoginButtonEnabled, on: self)
            .store(in: &cancellables)
    }
    
    // 이메일 유효성 검사
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // 비밀번호 유효성 검사
    private func isValidPassword(_ password: String) -> Bool {
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
    
    // 로그인 처리
    func login() async throws {
        do {
            let email = self.email
            let password = self.password
            let fcmToken = UserDefaults.standard.string(forKey: "fcmToken") ?? ""
            
            let usecase = LoginUseCase()
            let data = try await usecase.execute(email: email, password: password, fcmToken: fcmToken)
            
            guard let tokenData = data.token else {
                print("no token data in login response")
                return
            }
            
            // save tokens
            self.saveToken(tokenData)
            // save Temp NickName
            UserManager.tempNickname = data.tempNickname ?? ""
            
        } catch {
            SnackBar.shared.show(type: .errorMessage)
            throw error
        }
    }
    
    /// 로그인 응답으로부터 accessToken/refreshToken 저장
    private func saveToken(_ data: LoginRepsonseTokenData) {
        guard let accessToken = data.accessToken else {
            print("no accessToken in loginResponse")
            return
        }
        guard let refreshToken = data.refreshToken else {
            print("no refreshToken in loginResponse")
            return
        }
        
        UserManager.accessToken = accessToken
        UserManager.refreshToken = refreshToken
        print("login success! tokens saved!")
    }
}
