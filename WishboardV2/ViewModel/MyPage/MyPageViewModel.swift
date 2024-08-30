//
//  MyPageViewModel.swift
//  WishboardV2
//
//  Created by gomin on 8/24/24.
//

import Combine
import Foundation
import Core
import WBNetwork

class MypageViewModel {
    
    // Combine을 사용하여 사용자와 설정 데이터를 바인딩
    @Published var user: User
    @Published var settings: [Setting]
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 초기 데이터 설정
        self.user = User(profileImageUrl: "", nickname: "닉네임", email: "email@example.com", pushState: false)
        self.settings = [
            Setting(title: "알림 설정", type: .switch(isOn: false, showDivider: false)),
            Setting(title: "비밀번호 변경", type: .normal(showDivider: true)),
            Setting(title: "문의하기", type: .normal(showDivider: false)),
            Setting(title: "위시보드 이용방법", type: .normal(showDivider: false)),
            Setting(title: "이용약관", type: .normal(showDivider: false)),
            Setting(title: "개인정보 처리방침", type: .normal(showDivider: false)),
            Setting(title: "오픈소스 라이브러리", type: .normal(showDivider: false)),
            Setting(title: "버전정보", type: .subTitle(value: nil, showDivider: true)),
            Setting(title: "로그아웃", type: .normal(showDivider: false)),
            Setting(title: "회원탈퇴", type: .normal(showDivider: false)),
        ]
    }
    
    /// 유저 데이터 조회
    func fetchUserData() {
        Task {
            do {
                let usecase = GetUserInfoUseCase()
                let data = try await usecase.execute()
                
                DispatchQueue.main.async {
                    let userinfoResponse = data[0]
                    self.user = User(profileImageUrl: userinfoResponse.profile_img_url,
                                     nickname: userinfoResponse.nickname ?? "",
                                     email: userinfoResponse.email,
                                     pushState: userinfoResponse.push_state != 0)
                    
                    // pushState 업데이트
                    self.updatePushStateSetting(isOn: userinfoResponse.push_state != 0)
                    
                    // email 저장
                    UserManager.email = userinfoResponse.email
                }
            } catch {
                throw error
            }
        }
    }
    
    /// 프로필 편집 후 유저 프로필 업데이트
    func updateProfile(nickname: String, email: String, profileImageUrl: String) {
        // TODO: 프로필 편집 API
        user.nickname = nickname
        user.email = email
        user.profileImageUrl = profileImageUrl
    }
    
    /// 알림 토글 수정
    func updatePushStatus(isOn: Bool) {
        Task {
            do {
                let usecase = UpdatePushStateUseCase()
                _ = try await usecase.execute(state: isOn)
                
                self.updatePushStateSetting(isOn: isOn)
            } catch {
                throw error
            }
        }
    }
    
    /// 로그아웃
    func logout() async throws {
        do {
            let usecase = LogoutUseCase()
            _ = try await usecase.execute()
        } catch {
            throw error
        }
    }
    
    /// 로그아웃
    func deleteUser() async throws {
        do {
            let usecase = DeleteUserUseCase()
            _ = try await usecase.execute()
        } catch {
            throw error
        }
    }
    
    /// PushState 업데이트 (UI)
    private func updatePushStateSetting(isOn: Bool) {
        DispatchQueue.main.async {
            self.settings[0] = Setting(title: "알림 설정", type: .switch(isOn: isOn, showDivider: false))
        }
    }
}
