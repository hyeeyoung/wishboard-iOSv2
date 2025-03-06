//
//  EmailInputViewModel.swift
//  WishboardV2
//
//  Created by gomin on 3/4/25.
//

import Foundation
import Combine
import WBNetwork
import Moya

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
    
    /// 이메일 로그인
    /// 인증번호 받기
    public func getVerificationCode() async throws -> (Bool, String?) {
        do {
            let usecase = EmailLoginUseCase(repository: AuthRepository())
            let response = try await usecase.execute(email: email)
            let data = response.data
            
            let code = data?.verificationCode
            return (true, code)
        } catch {
            if let moyaError = error as? MoyaError, let response = moyaError.response {
                if response.statusCode == 404 {
                    print("존재하지 않는 유저")
                    return (false, nil)
                }
            }
            throw error
        }
    }
    
    /// 회원가입
    /// 이메일 검증
    public func checkEmailValidation() async throws -> Bool {
        do {
            let usecase = RegisterEmailUseCase(repository: AuthRepository())
            let response = try await usecase.execute(email: email)
            return true
        } catch {
            if let moyaError = error as? MoyaError, let response = moyaError.response {
                if response.statusCode == 409 {
                    print("이미 가입된 유저")
                    return false
                }
            }
            throw error
        }
    }
}
