//
//  AppDelegate.swift
//  WishboardV2
//
//  Created by gomin on 7/27/24.
//

import UIKit
import FirebaseMessaging
import Firebase
import UserNotifications
import Core

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if granted {
                print("알림 등록이 완료되었습니다.")
            }
        }
        application.registerForRemoteNotifications()
        
        // 네트워크 모니터링 시작
        NetworkMonitor.shared.startMonitoring()
        // 네트워크 체킹 감지
        NotificationCenter.default.addObserver(forName: .NetworkStatusChanged, object: nil, queue: .main) { notification in
            if let isConnected = notification.object as? Bool {
                if !isConnected {
                    UIApplication.shared.connectedScenes
                        .compactMap { $0 as? UIWindowScene }
                        .flatMap { $0.windows }
                        .first { $0.isKeyWindow }?
                        .endEditing(true)
                    SnackBar.shared.show(type: .networkCheck)
                } else {
                    SnackBar.shared.hideNetworkCheckingSnackBar()
                }
            }
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

// MARK: - FCM Messaging
extension AppDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("파이어베이스 토큰: \(fcmToken)")
        
        if let fcmToken = fcmToken {
            UserDefaults.standard.set(fcmToken, forKey: "fcmToken")
        }
        
//        // 디바이스가 변경되었을 때에만 (기존의 디바이스 토큰과 지금 얻은 디바이스 토큰값이 다를 때에만)
//        let preDeviceToken = UserManager.deviceToken
//        if preDeviceToken != fcmToken {
//            // 디바이스 토큰 변경 시
//            DispatchQueue.main.async {
//                UserManager.deviceToken = fcmToken
//            }
//        } else {
//            // 디바이스 토큰 그대로일 때
//        }
        
    }
//    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
//        print("Received data message: \(remoteMessage.appData)")
//    }
}
// MARK: - Notification
extension AppDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,willPresent notification: UNNotification,withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,didReceive response: UNNotificationResponse,withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
