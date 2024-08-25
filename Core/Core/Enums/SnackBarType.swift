//
//  SnackBarType.swift
//  Core
//
//  Created by gomin on 8/24/24.
//

import Foundation

public enum SnackBarType {
    case login
    case networkCheck
    case addFolder
    case modifyFolder
    case deleteFolder
    case deleteCartItem
    case addItem
    case modifyItem
    case deleteItem
    case modifyProfile
    case modifyPassword
    case deleteUser
    case ShoppingLink
    case failShoppingLink
    case emptyItemContent
    case errorMessage
    case test
    
    public var message: String {
        switch self {
        case .login: return "아이디 또는 비밀번호를 다시 확인해 주세요."
        case .networkCheck: return "네트워크 연결 상태를 확인해 주세요."
        case .addFolder: return "폴더를 추가했어요!😉"
        case .modifyFolder: return "폴더명을 수정했어요!📁"
        case .deleteFolder: return "폴더를 삭제했어요!🗑"
        case .deleteCartItem: return "장바구니에서 아이템을 삭제했어요! 🗑"
        case .addItem: return "아이템을 위시리스트에 추가했어요!👜"
        case .modifyItem: return "아이템을 수정했어요!✍️️"
        case .deleteItem: return "아이템을 위시리스트에서 삭제했어요!🗑"
        case .modifyProfile: return "프로필이 수정되었어요!👩‍🎤"
        case .modifyPassword: return "비밀번호가 변경되었어요!👩‍🎤"
        case .deleteUser: return "탈퇴 완료되었어요. 이용해주셔서 감사합니다!☺️"
        case .ShoppingLink: return "쇼핑몰 링크를 등록해 주세요!🛍️️"
        case .failShoppingLink: return "앗, 아이템 정보를 불러오지 못했어요🥲"
        case .emptyItemContent: return "앗, 상품명과 가격을 입력해 주세요😁"
        case .errorMessage: return "예상하지 못한 오류가 발생했어요!\n잠시후 다시 시도해주세요."
            
        case .test: return "로그아웃"
        }
    }
}
