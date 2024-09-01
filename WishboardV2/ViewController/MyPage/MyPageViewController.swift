//
//  MyPageViewController.swift
//  WishboardV2
//
//  Created by gomin on 8/24/24.
//

import Foundation
import UIKit
import MessageUI
import Combine
import Core

struct User {
    var profileImageUrl: String?
    var nickname: String
    var email: String
    var pushState: Bool
}

struct Setting {
    var title: String
    var type: SettingType
}

enum SettingType {
    case normal(showDivider: Bool) // 일반적인 셀
    case `switch`(isOn: Bool, showDivider: Bool) // 스위치가 있는 셀
    case subTitle(value: String?, showDivider: Bool) // 부제목이 있는 셀
}

class MypageViewController: UIViewController {
    
    private let mypageView = MypageView()
    private let viewModel = MypageViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.navigationController?.navigationBar.isHidden = true
        
        setupMyPageView()
        setupBindings()
        viewModel.fetchUserData() // 사용자 데이터 가져오기
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
    }
    
    private func setupMyPageView() {
        self.view.addSubview(mypageView)
        mypageView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.horizontalEdges.bottom.equalToSuperview()
        }
        mypageView.delegate = self
        mypageView.moveModifyProfile = { [weak self] in
            self?.didTapEditProfile()
        }
    }
    
    private func setupBindings() {
        // Combine을 사용하여 ViewModel의 데이터와 View를 바인딩
        viewModel.$user
            .sink { [weak self] user in
                self?.mypageView.updateProfile(with: user)
            }
            .store(in: &cancellables)
        
        viewModel.$settings
            .sink { [weak self] settings in
                self?.mypageView.updateSettings(with: settings)
            }
            .store(in: &cancellables)
    }
    
    func didTapEditProfile() {
        // 프로필 편집 화면으로 이동
        let profileImgUrl = self.viewModel.user.profileImageUrl
        let nickname = self.viewModel.user.nickname
        let nextVC = ModifyProfileViewController(profileImgUrl, nickname)
        
        nextVC.modifyProfileAction = { [weak self] in
            self?.viewModel.fetchUserData()
        }
        
        self.navigationController?.pushViewController(nextVC, animated: true)
    }
    
    /// 웹뷰로 화면 이동
    private func moveToWebVC(_ link: String, _ title: String) {
        let vc = WebViewController()
        vc.webURL = link
        vc.setUpTitle(title)
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension MypageViewController: MypageViewDelegate {
    /// 설정 탭 이벤트
    func didSelectSetting(at indexPath: IndexPath) {
        let tag = indexPath.row
        switch tag {
        case 1:
            // 비밀번호 변경
//            let vc = ModifyPasswordViewController()
//            self.navigationController?.pushViewController(vc, animated: true)
            break
        case 2:
            // 문의하기
            showSendEmail()
            break
        case 3:
            // 위시보드 이용 방법
            self.moveToWebVC(Storage.howToUseLink.rawValue, "위시보드 이용 방법")
            break
        case 4:
            // 이용약관
            self.moveToWebVC(Storage.useTermURL.rawValue, "이용약관")
            break
        case 5:
            // 개인정보처리방침
            self.moveToWebVC(Storage.privacyTermURL.rawValue, "개인정보 처리방침")
            break
        case 6:
            // 오픈소스 라이브러리
            self.moveToWebVC(Storage.openSourceLibraryURL.rawValue, "오픈소스 라이브러리")
            break
        case 8:
            // 로그아웃
            self.presentLogoutAlert()
            break
        case 9:
            // 회원탈퇴
            self.presentDeleteUserAlert()
            break
        default:
            break
        }
    }
    
    /// 로그아웃 팝업창 노출
    private func presentLogoutAlert() {
        let alert = AlertViewController(alertType: .logout)
        alert.buttonHandlers = [
            { _ in
                print("로그아웃 취소")
            }, { _ in
                self.requestLogout()
            }
        ]
        alert.modalTransitionStyle = .crossDissolve
        alert.modalPresentationStyle = .overFullScreen
        present(alert, animated: true, completion: nil)
    }
    
    /// 로그아웃 및 화면 전환, 유저데이터 삭제
    private func requestLogout() {
        Task {
            try await self.viewModel.logout()
            self.dismiss(animated: true)
            NotificationCenter.default.post(name: .SignOut, object: nil)
        }
    }
    
    /// 회원 탈퇴 알럿창 노출
    private func presentDeleteUserAlert() {
        let alert = AlertViewController(alertType: .accountDeletion)
        alert.buttonHandlers = [
            { _ in
                alert.dismissAlert()
                print("회원탈퇴 취소 버튼 클릭됨")
            }, { _ in
                if let email = alert.emailTextField.text {
                    guard let userEmail = UserManager.email else {
                        alert.dismissAlert()
                        return
                    }
                    // 입력된 이메일이 같을 때에만 회원 탈퇴 가능
                    if email == userEmail {
                        alert.dismissAlert()
                        self.requestDeleteUser()
                    } else {
                        alert.errorMessageLabel.isHidden = false
                    }
                } else {
                    alert.errorMessageLabel.isHidden = false
                }
            }
        ]
        alert.modalTransitionStyle = .crossDissolve
        alert.modalPresentationStyle = .overFullScreen
        present(alert, animated: true, completion: nil)
    }
    
    /// 회원탈퇴 및 화면 전환, 유저데이터 삭제
    private func requestDeleteUser() {
        Task {
            try await self.viewModel.deleteUser()
            self.dismiss(animated: true)
            NotificationCenter.default.post(name: .SignOut, object: nil)
            // 스낵바 출력
            SnackBar.shared.show(type: .deleteUser)
        }
    }
    
    /// 알림 허용 상태값 변경
    func pushStateStatusChanged(isOn: Bool) {
        viewModel.updatePushStatus(isOn: isOn)
    }
}

// MARK: - Mail Delegate
extension MypageViewController: MFMailComposeViewControllerDelegate {
    /// '문의하기' 메뉴 탭 이벤트 - 이메일 전송
    private func showSendEmail() {
        if MFMailComposeViewController.canSendMail() {
            let compseVC = MFMailComposeViewController()
            compseVC.mailComposeDelegate = self
            
            let deviceModel = UserManager.deviceModel ?? ""
            let osVersion = UserManager.OSVersion ?? ""
            let appVersion = UserManager.appVersion ?? ""
            
            let messageBody = """
                            Device: \(deviceModel)
                            OS Version: \(osVersion)
                            App Version: \(appVersion)
                            ---------------------
                            문의할 내용을 입력해 주세요.
                            """
            
            compseVC.setToRecipients(["wishboard2022@gmail.com"])
            compseVC.setSubject("위시보드팀에 문의하기")
            compseVC.setMessageBody(messageBody, isHTML: false)
            
            self.present(compseVC, animated: true, completion: nil)
            
        }
        else {
            self.showSendMailErrorAlert()
        }
    }
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    /// 이메일 전송 실패 알럿창
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertController(title: "메일을 전송 실패", message: "아이폰 이메일 설정을 확인하고 다시 시도해주세요.", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "확인", style: .default) {
            (action) in
            print("확인")
        }
        sendMailErrorAlert.addAction(confirmAction)
        self.present(sendMailErrorAlert, animated: true, completion: nil)
    }
}
