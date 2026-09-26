//
//  ItemSelectionFlow.swift
//  WishboardV2
//
//  Created by gomin on 2026/09/18.
//

import Foundation
import UIKit
import Core

/// 홈화면 / 폴더 상세 화면의 아이템 다중 선택 플로우에서 공통으로 사용하는 화면 표시 헬퍼
enum ItemSelectionFlow {

    /// 선택된 아이템 삭제 알럿
    static func presentDeleteAlert(
        on viewController: UIViewController,
        selectedCount: Int,
        onDelete: @escaping () -> Void
    ) {
        let alert = AlertViewController(alertType: .deleteItem)
        alert.customMessage = "선택된 \(selectedCount)개의 아이템을 삭제할까요?\n삭제된 아이템은 다시 복구할 수 없어요!"
        alert.buttonHandlers = [
            { _ in
                // 취소
            }, { _ in
                onDelete()
            }
        ]
        alert.modalTransitionStyle = .crossDissolve
        alert.modalPresentationStyle = .overFullScreen
        viewController.present(alert, animated: true, completion: nil)
    }
}
