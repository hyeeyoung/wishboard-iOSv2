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
    @UserDefault(key: UserDefaultKey.accessToken, defaultValue: nil)
    public static var accessToken: String?
    
    @UserDefault(key: UserDefaultKey.refreshToken, defaultValue: nil)
    public static var refreshToken: String?
    
    @UserDefault(key: UserDefaultKey.url, defaultValue: nil)
    public static var url: String?
    
    @UserDefault(key: UserDefaultKey.deviceModel, defaultValue: nil)
    public static var deviceModel: String?
    
    @UserDefault(key: UserDefaultKey.OSVersion, defaultValue: nil)
    public static var OSVersion: String?
    
    @UserDefault(key: UserDefaultKey.appVersion, defaultValue: nil)
    public static var appVersion: String?
    
    @UserDefault(key: UserDefaultKey.appBuildVersion, defaultValue: nil)
    public static var appBuildVersion: String?
    
    @UserDefault(key: UserDefaultKey.deviceToken, defaultValue: nil)
    public static var deviceToken: String?
    
    @UserDefault(key: UserDefaultKey.email, defaultValue: nil)
    public static var email: String?
    
    @UserDefault(key: UserDefaultKey.password, defaultValue: nil)
    public static var password: String?
    
    @UserDefault(key: UserDefaultKey.isFirstLogin, defaultValue: nil)
    public static var isFirstLogin: Bool?
    
    @UserDefault(key: UserDefaultKey.tempNickname, defaultValue: nil)
    public static var tempNickname: String?
    
    
    /// 사용자 데이터 삭제 (로그아웃, 탈퇴)
    public static func removeUserData() {
        UserDefaults.standard.removeObject(forKey: "accessToken")
        UserDefaults.standard.removeObject(forKey: "refreshToken")
        UserDefaults.standard.removeObject(forKey: "email")
        UserDefaults.standard.removeObject(forKey: "password")
        UserDefaults.standard.set(false, forKey: "isFirstLogin")
        UserDefaults(suiteName: "group.gomin.Wishboard.Share")?.removeObject(forKey: "accessToken")
        UserDefaults(suiteName: "group.gomin.Wishboard.Share")?.removeObject(forKey: "refreshToken")
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
