//
//  ItemSelectionFlow.swift
//  WishboardV2
//
//  Created by gomin on 2026/09/18.
//

import Foundation
import UIKit
import Core
import WBNetwork

/// 홈화면 / 폴더 상세 화면의 아이템 다중 선택 플로우에서 공통으로 사용하는 화면 표시 헬퍼
enum ItemSelectionFlow {

    /// '더 보기' 메뉴에 쓰는 시스템 아이콘
    private enum MenuIcon {
        static let wish = "heart"
        static let owned = "bag"
        static let removeFromFolder = "folder"
        static let delete = "trash"
    }

    // MARK: - 메뉴

    /// 위시템/소장템 전환 메뉴 항목.
    /// 이미 그 상태인 아이템만 골랐다면 바꿀 것이 없어 비활성으로 둡니다.
    static func makeConvertAction(to status: ItemStatusType,
                                  targetCount: Int,
                                  handler: @escaping () -> Void) -> UIAction {
        let title = (status == .wish) ? "위시템으로 전환" : "소장템으로 전환"
        let iconName = (status == .wish) ? MenuIcon.wish : MenuIcon.owned

        return UIAction(
            title: title,
            image: UIImage(systemName: iconName),
            attributes: targetCount > 0 ? [] : [.disabled]
        ) { _ in
            handler()
        }
    }

    /// 폴더에서 아이템 제거 메뉴 항목
    static func makeRemoveFromFolderAction(handler: @escaping () -> Void) -> UIAction {
        UIAction(
            title: "폴더에서 제거",
            image: UIImage(systemName: MenuIcon.removeFromFolder)
        ) { _ in
            handler()
        }
    }

    /// 아이템 삭제 메뉴 항목
    static func makeDeleteAction(handler: @escaping () -> Void) -> UIAction {
        UIAction(
            title: "삭제",
            image: UIImage(systemName: MenuIcon.delete),
            attributes: [.destructive]
        ) { _ in
            handler()
        }
    }

    // MARK: - 알럿

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
        present(alert, on: viewController)
    }

    /// 위시템/소장템 전환 알럿.
    /// 이미 그 상태인 아이템은 바뀌지 않으므로, 실제로 전환되는 개수를 안내합니다.
    static func presentConvertAlert(
        on viewController: UIViewController,
        to status: ItemStatusType,
        targetCount: Int,
        onConvert: @escaping () -> Void
    ) {
        let name = (status == .wish) ? "위시템" : "소장템"
        // 두 알럿의 첫 단어가 시안에서 서로 다릅니다. ('선택된' / '선택한')
        let subject = (status == .wish) ? "선택된" : "선택한"

        let alert = AlertViewController(
            alertType: .custom(
                title: "\(name)으로 전환",
                message: "\(subject) \(targetCount)개의 아이템이 \(name)으로 전환돼요.\n이미 \(name)인 아이템은 그대로 유지돼요.",
                buttonTitles: ["취소", "전환"],
                buttonColors: [.gray_600, .green_700]
            )
        )
        alert.buttonHandlers = [
            { _ in
                // 취소
            }, { _ in
                onConvert()
            }
        ]
        present(alert, on: viewController)
    }

    /// 폴더에서 아이템 제거 알럿
    static func presentRemoveFromFolderAlert(
        on viewController: UIViewController,
        selectedCount: Int,
        onRemove: @escaping () -> Void
    ) {
        let alert = AlertViewController(
            alertType: .custom(
                title: "폴더에서 아이템 제거",
                message: "선택한 \(selectedCount)개의 아이템을 폴더에서 제거할까요?\n폴더에서 제거해도 아이템은 삭제되지 않아요",
                buttonTitles: ["취소", "제거"],
                buttonColors: [.gray_600, .pink_700]
            )
        )
        alert.buttonHandlers = [
            { _ in
                // 취소
            }, { _ in
                onRemove()
            }
        ]
        present(alert, on: viewController)
    }

    // MARK: - Private

    private static func present(_ alert: AlertViewController, on viewController: UIViewController) {
        alert.modalTransitionStyle = .crossDissolve
        alert.modalPresentationStyle = .overFullScreen
        viewController.present(alert, animated: true, completion: nil)
    }
}
