//
//  StringEnum.swift
//  Wishboard
//
//  Created by gomin on 2023/03/16.
//

import Foundation

public enum Placeholder {
    // MARK: Authentication
    public static let email = "이메일을 입력해 주세요."
    public static let password = "비밀번호를 입력해 주세요."
    public static let authcode = "인증코드를 입력해 주세요."
    public static let nickname = "닉네임을 입력해 주세요."
    
    // MARK: Item
    public static let shoppingLink = "쇼핑몰 링크를 입력해 주세요."
    public static let folder = "폴더명을 입력해 주세요."
    
    // MARK: Upload Item
    public static let shareItemName = "상품명을 입력해 주세요."
    public static let shareItemPrice = "가격을 입력해 주세요."
    
    // MARK: Modify Password
    public static let newPassword = "새 비밀번호를 입력해 주세요."
    public static let rewritePassword = "새 비밀번호를 다시 입력해 주세요."
    
    public static let uploadItemName = "상품명을 입력해 주세요."
    public static let uploadItemPrice = "가격을 입력해 주세요."
    public static let uploadItemNoti = "재입고, 세일 시작 등 일정 알림을 받아보세요."
    public static let uploadItemLink = "쇼핑몰 링크를 추가해 보세요."
    public static let uploadItemMemo = "브랜드, 사이즈, 컬러 등 아이템 정보를 메모로 남겨보세요!😉"
}

public enum ErrorMessage {
    // MARK: Authentication
    public static let email = "이메일을 다시 확인해 주세요."
    public static let password = "8자리 이상의 영문자, 숫자, 특수 문자 조합으로 입력해 주세요."
    public static let passwordRewrite = "비밀번호가 일치하지 않아요!"
    public static let authcode = "인증코드를 다시 확인해 주세요."
    public static let nonExistAccount = "앗, 가입되지 않은 계정이에요! 가입하기부터 진행해 주세요."
    public static let existAccount = "앗, 이미 가입된 계정이에요! 로그인으로 진행해 주세요."
    
    // MARK: 500 Error
    public static let fiveHundredError = "예상하지 못한 오류가 발생했어요!\n잠시후 다시 시도해주세요."
    // MARK: Not Valid
    public static let shoppingLink = "쇼핑몰 링크를 다시 확인해 주세요."
    // MARK: Already Exist
    public static let sameFolderName = "동일이름의 폴더가 있어요!"
    public static let existingNickName = "이미 사용 중인 닉네임이에요!"
    public static let existingAccount = "앗, 이미 가입된 계정이에요! 로그인으로 진행해 주세요."
}

public enum Message {
    // MARK: Authentication
    public static let email = "이메일 인증으로 비밀번호를 찾을 수 있어요.\n실제 사용될 이메일로 입력해 주세요!"
    public static let password = "마지막 비밀번호 입력 단계예요!\n입력된 비밀번호로 바로 가입되니 신중히 입력해 주세요."
    public static let deleteUser = "정말 탈퇴하시겠습니까?\n탈퇴 시 앱 내 모든 데이터가 사라집니다.\n서비스를 탈퇴하시려면 이메일을 입력해 주세요."
    public static let toLogin = "이미 계정이 있으신가요?"
    public static let sendedEmail = "인증코드가 전송되었어요!\n이메일을 확인해 주세요."
    public static let lostPassword = "가입하신 이메일을 입력해 주세요!\n로그인을 위해 인증코드가 포함된 이메일을 보내드려요."
    
    // MARK: Label
    public static let login = "로그인"
    public static let item = "아이템"
    public static let folder = "폴더"
    public static let timer = "5:00"
    public static let count = "(0/10)자"
    public static let nickName = "닉네임"
    
    // MARK: Item
    public static let itemNotification = "30분 전에 일정을 알려드려요. 시간은 30분 단위로 설정 가능해요!"
    public static let shoppingLink = "복사한 링크로 아이템을 불러올 수 있어요!"
    public static let onboarding = "흩어져있는 위시리스트를\n위시보드로 간편하게 통합 관리해 보세요!️"
}

public enum Title {
    // MARK: Authentication
    public static let register = "가입하기"
    public static let login = "로그인하기"
    public static let loginByEmail = "이메일로 로그인하기"
    public static let email = "이메일"
    public static let password = "비밀번호"
    public static let modifyPassword = "비밀번호 변경"
    
    public static let newPassword = "새 비밀번호"
    public static let passwordRewrite = "새 비밀번호 재입력"
    
    // MARK: Camera
    public static let camera = "사진 찍기"
    public static let album = "사진 보관함"
    public static let cancel = "취소"
    
    // MARK: Account
    public static let modifyProfile = "프로필 수정"
    public static let mypage = "마이페이지"
    
    // MARK: Item
    public static let itemName = "상품명"
    public static let price = "가격"
    public static let notification = "알림"
    public static let shoppingMallLink = "쇼핑몰 링크"
    public static let addItem = "아이템 추가"
    public static let modifyItem = "아이템 수정"
    public static let memo = "메모"
    public static let shoppingLinkBottomSheet = "쇼핑몰 링크 추가"
    
    // MARK: Folder
    public static let folder = "폴더"
    public static let addFolder = "새 폴더 추가"
    public static let modifyFolder = "폴더명 수정"
    
    // MARK: Notification
    public static let notificationSetting = "상품 알림 설정"
    public static let notificationItem = "상품 일정 알림"
    
    public static let stepTwo = "2/2 단계"
}

public enum Button {
    // MARK: Authentication
    public static let login = "로그인하기"
    public static let getEmail = "인증메일 받기"
    public static let register = "가입하기"
    public static let lostPassword = "비밀번호를 잊으셨나요?"
    public static let doLogin = "로그인 후 아이템을 추가해보세요!"
    
    // MARK: Item
    public static let item = "아이템 불러오기"
    public static let addToWishList = "위시리스트에 추가"
    public static let complete = "완료"
    public static let next = "다음"
    public static let save = "저장"
    public static let add = "추가"
    public static let modify = "수정"
    public static let howTo = "네! 알겠어요"
    public static let setNoti = "상품 알림 설정하기"
    
    public static let addFolder = "+ 새 폴더"
}

public enum EmptyMessage {
    public static let item = "앗, 아이템이 없어요!\n갖고 싶은 아이템을 등록해보세요!"
    public static let folder = "앗, 폴더가 없어요!\n폴더를 추가해서 아이템을 정리해보세요!"
    public static let cart = "앗, 장바구니가 비어있어요!\n구매할 아이템을 장바구니에 담아보세요!"
}

public enum RegularExpression {
    public static let shoppingLink = "^(https?://)?(www\\.)?([-a-z0-9]{1,63}\\.)*?[a-z0-9][-a-z0-9]{0,61}[a-z0-9]\\.[a-z]{2,6}(/[-\\w@\\+\\.~#\\?&/=%]*)?$"
    public static let password = "^(?=.*[A-Za-z])(?=.*[0-9])(?=.*[!@#$%^&*()_+=-]).{8,50}"
}

public enum Item {
    public static let total = "전체"
    public static let zero = "0"
    public static let won = "원"
    public static let count = "개"
}

public enum Alarm: String {
    case restock = "재입고"
    case open = "오픈"
    case preorder = "프리오더"
    case saleStart = "세일 시작"
    case saleEnd = "세일 마감"
    case reminder = "리마인드"
    case notification = " 알림"
    
    // TODO: 프리오더 API STRING 확인해야함
    
    public var apiString: String {
        switch self {
        case .restock:
            return "RESTOCK"
        case .open:
            return "OPEN"
        case .preorder:
            return "PRE_ORDER"
        case .saleStart:
            return "SALE_START"
        case .saleEnd:
            return "SALE_END"
        case .reminder:
            return "REMINDER"
        default: return ""
        }
    }
    
    /// 한글 스트링을 ApiString으로 변환
    /// 예) "재입고" → "RESTOCK"
    public static func apiString(from label: String) -> String? {
        guard let notification = Alarm(rawValue: label) else {
            return nil
        }
        return notification.apiString
    }
}

public enum BottomSheetTitle {
    public static let shoppingMallLink = "쇼핑몰 링크로 아이템 불러오기"
    public static let folderSetting = "폴더 선택"
}
