//
//  UserManager.swift
//  Core
//
//  Created by gomin on 8/16/24.
//

import Foundation

@propertyWrapper
public struct UserDefault<T> {
    public let key: String
    public let defaultValue: T
    public let storage: UserDefaults
    
    public var wrappedValue: T {
        get { self.storage.object(forKey: self.key) as? T ?? self.defaultValue }
        set { self.storage.set(newValue, forKey: self.key) }
    }
    
    public init(key: String, defaultValue: T, storage: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.storage = storage
    }
}

public class UserManager {
    // 앱 그룹을 사용하는 UserDefaults 인스턴스 생성
    private static let sharedDefaults = UserDefaults(suiteName: "group.gomin.Wishboard.Share")!

    @UserDefault(key: UserDefaultKey.accessToken, defaultValue: nil, storage: sharedDefaults)
    public static var accessToken: String?
    
    @UserDefault(key: UserDefaultKey.refreshToken, defaultValue: nil, storage: sharedDefaults)
    public static var refreshToken: String?
    
    @UserDefault(key: UserDefaultKey.deviceInfo, defaultValue: nil, storage: sharedDefaults)
    public static var deviceInfo: String?
    
    @UserDefault(key: UserDefaultKey.url, defaultValue: nil, storage: sharedDefaults)
    public static var url: String?
    
    @UserDefault(key: UserDefaultKey.deviceModel, defaultValue: nil, storage: sharedDefaults)
    public static var deviceModel: String?
    
    @UserDefault(key: UserDefaultKey.OSVersion, defaultValue: nil, storage: sharedDefaults)
    public static var OSVersion: String?
    
    @UserDefault(key: UserDefaultKey.appVersion, defaultValue: nil, storage: sharedDefaults)
    public static var appVersion: String?
    
    @UserDefault(key: UserDefaultKey.appBuildVersion, defaultValue: nil, storage: sharedDefaults)
    public static var appBuildVersion: String?
    
    @UserDefault(key: UserDefaultKey.deviceToken, defaultValue: nil, storage: sharedDefaults)
    public static var deviceToken: String?
    
    @UserDefault(key: UserDefaultKey.email, defaultValue: nil, storage: sharedDefaults)
    public static var email: String?
    
    @UserDefault(key: UserDefaultKey.isFirstLogin, defaultValue: nil, storage: sharedDefaults)
    public static var isFirstLogin: Bool?
    
    @UserDefault(key: UserDefaultKey.tempNickname, defaultValue: "", storage: sharedDefaults)
    public static var tempNickname: String?

    @UserDefault(key: UserDefaultKey.gridColumnType, defaultValue: 2, storage: sharedDefaults)
    public static var gridColumnType: Int
    
    /// 예전 버전이 평문으로 저장해 두던 비밀번호 키. 지우기 위해서만 남겨 둡니다.
    private static let legacyPasswordKey = "password"

    /// 사용자 데이터 삭제 (로그아웃, 탈퇴)
    public static func removeUserData() {
        sharedDefaults.removeObject(forKey: UserDefaultKey.accessToken)
        sharedDefaults.removeObject(forKey: UserDefaultKey.refreshToken)
        sharedDefaults.removeObject(forKey: UserDefaultKey.email)
        // 계정을 바꿔 로그인했을 때 이전 사용자의 닉네임이 보이지 않도록 함께 지웁니다.
        sharedDefaults.removeObject(forKey: UserDefaultKey.tempNickname)
        sharedDefaults.removeObject(forKey: legacyPasswordKey)
        sharedDefaults.set(false, forKey: UserDefaultKey.isFirstLogin)
    }

    /// 앱 시작 시 1회 호출합니다.
    ///
    /// 예전 버전이 기기에 남겨 둔 평문 비밀번호를 지웁니다.
    /// 로그아웃을 하지 않은 기존 사용자의 기기에는 아직 남아 있을 수 있어, 로그인 여부와 무관하게 지웁니다.
    public static func purgeLegacyCredentials() {
        sharedDefaults.removeObject(forKey: legacyPasswordKey)
    }
}

public struct UserDefaultKey {
    public static let accessToken = "accessToken"
    public static let refreshToken = "refreshToken"
    public static let deviceInfo = "deviceInfo"
    
    public static let url = "url"
    
    public static let deviceModel = "deviceModel"
    public static let OSVersion = "OSVersion"
    public static let appVersion = "appVersion"
    public static let appBuildVersion = "appBuildVersion"
    public static let deviceToken = "deviceToken"
    
    public static let email = "email"
    public static let isFirstLogin = "isFirstLogin"
    public static let tempNickname = "tempNickname"
    public static let gridColumnType = "gridColumnType"
}
