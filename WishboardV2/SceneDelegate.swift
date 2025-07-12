//
//  SceneDelegate.swift
//  WishboardV2
//
//  Created by gomin on 7/27/24.
//

import UIKit
import Core

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        
        // Notification 수신 등록
        NotificationCenter.default.addObserver(self, selector: #selector(signOutEvent), name: .SignOut, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NetworkErrorEvent), name: .ReceivedNetworkError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showSnackBar), name: .ShowSnackBar, object: nil)
        
        // MARK: Navigation controller
        let splashVC = SplashViewController()
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window?.windowScene = windowScene
        window?.rootViewController = splashVC
        window?.makeKeyAndVisible()
        
        // MARK: Light mode
        //iOS 13 부터 다크모드가 적용되므로 다음과 같은 조건문 성립.
        if #available(iOS 13.0, *) {
            // iOS 13 부터는 다크모드로만 제한.
            self.window?.overrideUserInterfaceStyle = UIUserInterfaceStyle.light
        } else {
            self.window?.overrideUserInterfaceStyle = UIUserInterfaceStyle.light
        }
        
        // 일정 시간 후에 온보딩 화면으로 전환
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // 앱 버전 체크 후 화면이동
            splashVC.checkAppVersion()
        }
    }
    
    /// 네트워크 에러 발생 시 온보딩으로 이동
    @objc private func NetworkErrorEvent() {
        DispatchQueue.main.async {
            // 기존 유저 데이터 삭제
            UserManager.removeUserData()
            // 온보딩 화면으로 이동하는 로직
            self.setRootOnboarding()
        }
    }
    
    /// 로그아웃 시 온보딩으로 이동
    @objc private func signOutEvent() {
        DispatchQueue.main.async {
            // 기존 유저 데이터 삭제
            UserManager.removeUserData()
            // 온보딩 화면으로 이동하는 로직
            self.setRootOnboarding()
        }
    }
    
    /// 스낵바 출력
    @objc private func showSnackBar(_ notification: Foundation.Notification) {
        if let snackBarType = notification.userInfo?["SnackBarType"] as? SnackBarType {
            SnackBar.shared.show(type: snackBarType)
        }
    }
    
    /// 메인 화면 이동
    private func setRootTabBar() {
        let tabBarController = TabBarViewController()
        tabBarController.modalPresentationStyle = .fullScreen
        self.window?.rootViewController = tabBarController
    }
    
    /// 온보딩 화면 설정
    private func setRootOnboarding() {
        let onboardingViewController = OnboardingViewController()
        let navigationController = UINavigationController(rootViewController: onboardingViewController)
        self.window?.rootViewController = navigationController
        self.window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    /// rootVC를 바꾸는 메소드
    func changeRootVC(_ vc:UIViewController, animated: Bool) {
        guard let window = self.window else { return }
        window.rootViewController = vc // 전환
        window.makeKeyAndVisible()
        
        UIView.transition(with: window, duration: 0.2, options: [.transitionCrossDissolve], animations: nil, completion: nil)
    }
}

