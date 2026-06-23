//
//  AlertType.swift
//  Core
//
//  Created by gomin on 8/25/24.
//

import Foundation
import UIKit

public enum AlertType: Equatable {
    case allowAlarm     // 알림 허용
    case logout         // 로그아웃
    case accountDeletion // 회원탈퇴
    case deleteItem     // 아이템 삭제
    case deleteFolder   // 폴더 삭제
    case deleteCart     // 장바구니 삭제
    case recommendUpdate    // 업데이트 권유
    case forceUpdate        // 업데이트 강제
    case serviceStop        // 서비스 일시 중단
    case custom(title: String, message: String, buttonTitles: [String], buttonColors: [UIColor])

    public var title: String {
        switch self {
        case .allowAlarm:
            return "알림 허용"
        case .logout:
            return "로그아웃"
        case .accountDeletion:
            return "회원 탈퇴"
        case .deleteItem:
            return "아이템 삭제"
        case .deleteFolder:
            return "폴더 삭제"
        case .deleteCart:
            return "장바구니에서 삭제"
        case .recommendUpdate, .forceUpdate:
            return "업데이트 안내"
        case .serviceStop:
            return "서비스 일시 중단 안내"
        case .custom(let title, _, _, _):
            return title
        }
    }

    public var message: String {
        switch self {
        case .allowAlarm:
            return "알림을 받아보시겠어요?\n직접 등록하신 아이템의 재입고 날짜 등의\n상품 일정 알림을 받으실 거에요."
        case .logout:
            return "정말 로그아웃 하시겠어요?"
        case .accountDeletion:
            return "정말 탈퇴하시겠습니까?\n탈퇴 시 앱 내 모든 데이터가 사라집니다.\n서비스를 탈퇴하시려면 이메일을 입력해 주세요."
        case .deleteItem:
            return "정말 아이템을 삭제하시겠어요?\n삭제된 아이템은 다시 복구할 수 없어요!"
        case .deleteFolder:
            return "정말 폴더를 삭제하시겠어요?\n폴더가 삭제되어도 아이템은 사라지지 않아요"
        case .deleteCart:
            return "정말 장바구니에서 아이템을 삭제하시겠어요?"
        case .recommendUpdate, .forceUpdate:
            return "위시보드가 유저분들에게 더 나은 경험을\n제공하기 위해 사용성을 개선했어요!\n 더 새로워진 위시보드를 만나보세요 😆"
        case .serviceStop:
            return "서버 이전으로 서비스가\n일시 중단되오니 양해 부탁드립니다.\n보다 안정적인 위시보드로 곧 돌아올게요!\n자세한 사항은 공지사항을 확인해 주세요 😉"
        case .custom(_, let message, _, _):
            return message
        }
    }

    public var buttonTitles: [String] {
        switch self {
        case .allowAlarm:
            return ["나중에", "허용"]
        case .logout:
            return ["취소", "로그아웃"]
        case .accountDeletion:
            return ["취소", "탈퇴"]
        case .deleteItem, .deleteFolder, .deleteCart:
            return ["취소", "삭제"]
        case .recommendUpdate:
            return ["나중에", "업데이트"]
        case .forceUpdate:
            return ["업데이트"]
        case .serviceStop:
            return ["공지사항 확인", "앱 종료"]
        case .custom(_, _, let buttonTitles, _):
            return buttonTitles
        default:
            return ["확인"]
        }
    }

    public var buttonColors: [UIColor] {
        switch self {
        case .logout, .accountDeletion, .deleteItem, .deleteFolder, .deleteCart, .serviceStop:
            return [.gray_600, .pink_700]
        case .allowAlarm, .recommendUpdate:
            return [.gray_600, .blue_700]
        case .forceUpdate:
            return [.blue_700]
        case .custom(_, _, _, let buttonColors):
            return buttonColors
        }
    }
    
    // Equatable 프로토콜 구현
    public static func ==(lhs: AlertType, rhs: AlertType) -> Bool {
        switch (lhs, rhs) {
        case (.logout, .logout),
             (.accountDeletion, .accountDeletion):
            return true
        case (.custom(let lhsTitle, let lhsMessage, let lhsButtonTitles, let lhsButtonColors),
              .custom(let rhsTitle, let rhsMessage, let rhsButtonTitles, let rhsButtonColors)):
            return lhsTitle == rhsTitle &&
                   lhsMessage == rhsMessage &&
                   lhsButtonTitles == rhsButtonTitles &&
                   lhsButtonColors == rhsButtonColors
        default:
            return false
        }
    }
}
