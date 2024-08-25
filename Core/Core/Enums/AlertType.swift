//
//  AlertType.swift
//  Core
//
//  Created by gomin on 8/25/24.
//

import Foundation
import UIKit

public enum AlertType: Equatable {
    case logout         // 로그아웃
    case accountDeletion // 회원탈퇴
    case deleteItem     // 아이템 삭제
    case deleteFolder   // 폴더 삭제
    case custom(title: String, message: String, buttonTitles: [String], buttonColors: [UIColor])

    public var title: String {
        switch self {
        case .logout:
            return "로그아웃"
        case .accountDeletion:
            return "회원탈퇴"
        case .deleteItem:
            return "아이템 삭제"
        case .deleteFolder:
            return "폴더 삭제"
        case .custom(let title, _, _, _):
            return title
        }
    }

    public var message: String {
        switch self {
        case .logout:
            return "정말 로그아웃 하시겠어요?"
        case .accountDeletion:
            return "정말 탈퇴하시겠습니까?\n탈퇴 시 앱 내 모든 데이터가 사라집니다.\n서비스를 탈퇴하시려면 이메일을 입력해 주세요."
        case .deleteItem:
            return "정말 아이템을 삭제하시겠어요?\n삭제된 아이템은 다시 복구할 수 없어요!"
        case .deleteFolder:
            return "정말 폴더를 삭제하시겠어요?\n폴더가 삭제되어도 아이템은 사라지지 않아요"
        case .custom(_, let message, _, _):
            return message
        }
    }

    public var buttonTitles: [String] {
        switch self {
        case .logout:
            return ["취소", "로그아웃"]
        case .accountDeletion:
            return ["취소", "탈퇴하기"]
        case .deleteItem, .deleteFolder:
            return ["취소", "삭제"]
        case .custom(_, _, let buttonTitles, _):
            return buttonTitles
        default:
            return ["확인"]
        }
    }

    public var buttonColors: [UIColor] {
        switch self {
        case .logout, .accountDeletion, .deleteItem, .deleteFolder:
            return [.gray_600, .pink_700]
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
