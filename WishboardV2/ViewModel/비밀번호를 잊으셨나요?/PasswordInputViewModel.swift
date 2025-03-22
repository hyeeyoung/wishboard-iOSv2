//
//  PasswordInputViewModel.swift
//  WishboardV2
//
//  Created by gomin on 3/5/25.
//

import Foundation
import Combine
import WBNetwork
import Core
import Moya

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
    
    /// 이메일로 로그인하기
    /// 인증코드 검증
    public func loginWithoutPassword(verify: Bool, email: String) async throws {
        do {
            guard let fcmToken = UserDefaults.standard.string(forKey: "fcmToken") else {
                print("기기에 파이어베이스 토큰 부재")
                return
            }
            
            let usecase = LoginWithoutPasswordUseCase(repository: AuthRepository())
            let response = try await usecase.execute(verify: verify, email: email, fcmToken: fcmToken)
            
            let tokenData = response.token
            let accessToken = tokenData?.accessToken
            let refreshToken = tokenData?.refreshToken
            let pushState = response.pushState
            let tempNickname = response.tempNickname ?? ""
            
            // 기기에 토큰 정보 저장
            UserManager.accessToken = accessToken
            UserManager.refreshToken = refreshToken
            UserManager.tempNickname = tempNickname
            
        } catch {
            if let moyaError = error as? MoyaError, let response = moyaError.response {
                if response.statusCode == 404 {
                    print("존재하지 않는 유저")
                    return
                }
            }
            throw error
        }
    }
    
    /// 회원가입
    public func register(email: String) async throws {
        do {
            guard let fcmToken = UserDefaults.standard.string(forKey: "fcmToken") else {
                print("기기에 파이어베이스 토큰 부재")
                return
            }
            
            let usecase = RegisterUseCase(repository: AuthRepository())
            let response = try await usecase.execute(email: email, password: input, fcmToken: fcmToken)
            
            let tokenData = response.token
            let accessToken = tokenData?.accessToken
            let refreshToken = tokenData?.refreshToken
            let pushState = response.pushState
            let tempNickname = response.tempNickname ?? ""
            
            // 기기에 토큰 정보 저장
            UserManager.accessToken = accessToken
            UserManager.refreshToken = refreshToken
            UserManager.tempNickname = tempNickname
            
            // 첫 로그인 유무 저장
            UserManager.isFirstLogin = true
            
        } catch {
            if let moyaError = error as? MoyaError, let response = moyaError.response {
                if response.statusCode == 404 {
                    print("이미 존재하는 fcmToken")
                    return
                }
            }
            throw error
        }
    }
}
