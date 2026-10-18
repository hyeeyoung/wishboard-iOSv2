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

    // TODO: '위시템으로 전환'과 '삭제'는 아직 디자인 에셋이 없어 시스템 아이콘을 씁니다.
    // 에셋을 받으면 아래 owned / removeFromFolder 처럼 바꾸면 됩니다. 그때 걸리는 것들:
    //  1) 삭제 항목은 attributes 에 .destructive 가 있어 글자와 아이콘이 빨강으로 강제됩니다.
    //     디자인이 빨강이 아니라면 .destructive 를 빼야 합니다.
    //  2) 아이콘 크기를 지정하는 API 가 없어, 에셋을 알맞은 크기로 만들어 두어야 합니다.
    //     (시스템 아이콘의 SymbolConfiguration 같은 수단이 없습니다)

    /// '더 보기' 메뉴 아이콘
    private enum MenuIcon {
        /// 디자인 에셋 (20x20 SVG)
        static let owned = Image.menuShoppingBag
        static let removeFromFolder = Image.menuFolder

        /// 아직 에셋이 없어 시스템 아이콘을 쓰는 항목
        static let wish = UIImage(systemName: "heart")
        static let delete = UIImage(systemName: "trash")
    }

    // MARK: - 메뉴

    /// 위시템/소장템 전환 메뉴 항목.
    /// 바꿀 아이템이 없을 때는 호출하는 쪽에서 메뉴에 넣지 않습니다.
    static func makeConvertAction(to status: ItemStatusType,
                                  handler: @escaping () -> Void) -> UIAction {
        let title = (status == .wish) ? "위시템으로 전환" : "소장템으로 전환"
        let icon = (status == .wish) ? MenuIcon.wish : MenuIcon.owned

        return UIAction(
            title: title,
            image: icon
        ) { _ in
            handler()
        }
    }

    /// 폴더에서 아이템 제거 메뉴 항목
    static func makeRemoveFromFolderAction(handler: @escaping () -> Void) -> UIAction {
        UIAction(
            title: "폴더에서 제거",
            image: MenuIcon.removeFromFolder
        ) { _ in
            handler()
        }
    }

    /// 아이템 삭제 메뉴 항목
    static func makeDeleteAction(handler: @escaping () -> Void) -> UIAction {
        UIAction(
            title: "삭제",
            image: MenuIcon.delete,
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
