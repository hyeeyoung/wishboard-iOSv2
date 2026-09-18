//
//  ItemSelectionFlow.swift
//  WishboardV2
//
//  Created by gomin on 2026/09/18.
//

import Foundation
import UIKit
import SnapKit
import Core

/// 홈화면 / 폴더 상세 화면의 아이템 다중 선택 플로우에서 공통으로 사용하는 화면 표시 헬퍼
enum ItemSelectionFlow {

    /// more 버튼 탭 시 노출되는 액션시트
    static func presentSelectionActionSheet(
        on viewController: UIViewController,
        onSelectItems: @escaping () -> Void
    ) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(
            UIAlertAction(title: "아이템 선택", style: .default) { _ in
                onSelectItems()
            }
        )
        actionSheet.addAction(UIAlertAction(title: "취소", style: .cancel))
        actionSheet.view.tintColor = .gray_700

        // iPad에서 액션시트는 popover로 표시되므로 anchor가 필요합니다.
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(
                x: viewController.view.bounds.midX,
                y: viewController.view.bounds.maxY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        viewController.present(actionSheet, animated: true) {
            actionSheet.view.tintColor = .gray_700
        }
    }

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

    /// 삭제 API 호출 동안 화면 정 가운데에 노출되는 기본 로딩 인디케이터
    @discardableResult
    static func showLoading(on viewController: UIViewController) -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .gray_700
        indicator.hidesWhenStopped = true

        viewController.view.addSubview(indicator)
        indicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        indicator.startAnimating()

        return indicator
    }

    static func hideLoading(_ indicator: UIActivityIndicatorView?) {
        indicator?.stopAnimating()
        indicator?.removeFromSuperview()
    }
}
