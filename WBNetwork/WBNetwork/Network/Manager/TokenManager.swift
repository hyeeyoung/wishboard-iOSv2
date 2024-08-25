//
//  TokenManager.swift
//  WishboardV2
//
//  Created by gomin on 8/3/24.
//

import Foundation

class TokenManager {
    // 토큰을 저장할 변수를 원자적으로 갱신하기 위해 Atomic 프로퍼티 래퍼를 사용
    @Atomic var accessToken: String?
    // Singleton 인스턴스 생성
    static let shared = TokenManager()
    // 토큰 발급 메서드
    func issueToken(newToken: String, completion: @escaping (String) -> Void) {
       // 토큰을 Atomic 프로퍼티에 저장
       self.accessToken = newToken
       // 발급된 토큰을 완료 핸들러로 반환
       completion(newToken)
   }
}

// Atomic 프로퍼티 래퍼 구현
@propertyWrapper
struct Atomic<Value> {
    private var value: Value
    private let queue = DispatchQueue(label: "Atomic serial queue")
    
    init(wrappedValue value: Value) {
       self.value = value
    }
    var wrappedValue: Value {
       get {
           return queue.sync { value }
       }
       set {
           queue.sync { value = newValue }
       }
    }
}
