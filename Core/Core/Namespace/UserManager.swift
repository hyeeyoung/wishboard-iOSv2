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
    
    @UserDefault(key: UserDefaultKey.password, defaultValue: nil, storage: sharedDefaults)
    public static var password: String?
    
    @UserDefault(key: UserDefaultKey.isFirstLogin, defaultValue: nil, storage: sharedDefaults)
    public static var isFirstLogin: Bool?
    
    @UserDefault(key: UserDefaultKey.tempNickname, defaultValue: "", storage: sharedDefaults)
    public static var tempNickname: String?
    
    /// 사용자 데이터 삭제 (로그아웃, 탈퇴)
    public static func removeUserData() {
        let defaults = UserDefaults(suiteName: "group.gomin.Wishboard.Share")!
        defaults.removeObject(forKey: UserDefaultKey.accessToken)
        defaults.removeObject(forKey: UserDefaultKey.refreshToken)
        defaults.removeObject(forKey: UserDefaultKey.email)
        defaults.removeObject(forKey: UserDefaultKey.password)
        defaults.set(false, forKey: UserDefaultKey.isFirstLogin)
    }
}

public struct UserDefaultKey {
    public static let accessToken = "accessToken"
    public static let refreshToken = "refreshToken"
    
    public static let url = "url"
    
    public static let deviceModel = "deviceModel"
    public static let OSVersion = "OSVersion"
    public static let appVersion = "appVersion"
    public static let appBuildVersion = "appBuildVersion"
    public static let deviceToken = "deviceToken"
    
    public static let email = "email"
    public static let password = "password"
    public static let isFirstLogin = "isFirstLogin"
    public static let tempNickname = "tempNickname"
    
}
