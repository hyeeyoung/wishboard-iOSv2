//
//  UIViewControllerExtension.swift
//  WishboardV2
//
//  Created by gomin on 11/7/26.
//

import UIKit

extension UIViewController {

    /// 상세 화면을 띄워도 되는 상태인지.
    ///
    /// 셀을 빠르게 연타하면 상세 화면이 여러 번 쌓입니다. 같은 아이템 화면이 중복으로 떠서
    /// 각자 조회를 돌리고, 그 사이 뒤로 가기가 겹치면 비정상 종료로 이어질 수 있습니다.
    ///
    /// `pushViewController` 는 호출 즉시 `viewControllers` 에 반영되므로, 화면 전환
    /// 애니메이션이 끝나기 전이라도 두 번째 탭은 여기서 걸러집니다.
    var canPushDetail: Bool {
        guard let navigationController = navigationController else { return false }
        // 이미 다른 화면이 올라갔거나, 전환이 진행 중이면 무시합니다.
        return navigationController.topViewController === self
            && transitionCoordinator == nil
    }
}
