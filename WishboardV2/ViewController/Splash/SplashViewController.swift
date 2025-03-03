//
//  SplashViewController.swift
//  WishboardV2
//
//  Created by gomin on 7/27/24.
//

import Foundation
import UIKit
import Core
import WBNetwork

class SplashViewController: UIViewController {
    
    private let logo = UIImageView().then {
        $0.image = Image.wishboardLogo
    }
    private let debugVersion = UILabel().then {
        $0.text = "Version: \(Bundle.appVersion)(\(Bundle.appBuildVersion))\nServer: \(NetworkMacro.BaseURL)"
        $0.numberOfLines = 0
        $0.font = UIFont.systemFont(ofSize: 10)
        $0.textColor = .gray_700
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white

        setupUI()
    }

    private func setupUI() {
        self.view.addSubview(logo)
        
        logo.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(56)
        }
        
        #if DEBUG
        self.setUpVersionLabel("dev")
        #endif
        
    }
    
    private func setUpVersionLabel(_ version: String) {
        self.view.addSubview(debugVersion)
        
        debugVersion.snp.makeConstraints { make in
            make.leading.equalTo(logo)
            make.bottom.equalToSuperview().inset(50)
        }
    }

    public func checkAppVersion() {
        Task {
            do {
                let usecase = GetVersionUseCase(repository: VersionRepository())
                let response = try await usecase.execute()
                
                // 1. 서버로부터 받은 데이터 (API 응답)
                guard let minVersion = response.minVersion,
                      let recommendedVersion = response.recommendedVersion,
                      let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
                    return
                }
                
                // 2. 버전 비교
                if isVersion(currentVersion, lessThan: minVersion) {
                    // 강제 업데이트 알럿
                    self.showForceUpdateAlert()
                } else if isVersion(currentVersion, lessThan: recommendedVersion) {
                    // 권장 업데이트 알럿
                    self.showRecommendUpdateAlert()
                } else {
                    // 최신 버전, 다음 화면으로 이동
                    moveToNextScreen()
                }
            } catch {
                throw error
            }
        }
    }

    // 3. 버전 비교 헬퍼 함수
    private func isVersion(_ currentVersion: String, lessThan targetVersion: String) -> Bool {
        return currentVersion.compare(targetVersion, options: .numeric) == .orderedAscending
    }

    // 4. 알럿창 표시 함수
    /// 권장 업데이트 알럿
    private func showRecommendUpdateAlert() {
        // Show Alert
        let alert = AlertViewController(alertType: .recommendUpdate)
        alert.buttonHandlers = [
            { _ in
                self.quitButtonDidTap()
            }, { _ in
                self.appUpdateButtonDidTap()
            }
        ]
        alert.modalTransitionStyle = .crossDissolve
        alert.modalPresentationStyle = .overFullScreen
        self.present(alert, animated: true, completion: nil)
    }
    /// 강제 업데이트 알럿
    private func showForceUpdateAlert() {
        // Show Alert
        let alert = AlertViewController(alertType: .forceUpdate)
        alert.buttonHandlers = [
            { _ in
                self.appUpdateButtonDidTap()
            }
        ]
        alert.modalTransitionStyle = .crossDissolve
        alert.modalPresentationStyle = .overFullScreen
        self.present(alert, animated: true, completion: nil)
    }

    // 5. 화면 이동 함수 (알럿창 이벤트 완료 후)
    private func moveToNextScreen() {
        guard let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate else { return }

        let nextVC: UIViewController
        if let _ = UserManager.accessToken, let _ = UserManager.refreshToken {
            nextVC = TabBarViewController() // 메인 화면
        } else {
            let onboardingVC = OnboardingViewController() // 온보딩 화면
            nextVC = UINavigationController(rootViewController: onboardingVC)
        }

        sceneDelegate.changeRootVC(nextVC, animated: true)
    }
    
    @objc private func appUpdateButtonDidTap() {
        // 앱 업데이트를 위해 앱스토어로 이동
        if let appStoreURL = URL(string: "https://itunes.apple.com/app/6443808936") {
            if UIApplication.shared.canOpenURL(appStoreURL) {
                UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
            }
        }
    }
    
    @objc private func quitButtonDidTap() {
        self.dismiss(animated: false)
        moveToNextScreen()
    }
}
