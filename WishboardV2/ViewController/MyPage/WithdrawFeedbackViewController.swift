//
//  WithdrawFeedbackViewController.swift
//  WishboardV2
//
//  Created by gomin on 10/8/26.
//

import Foundation
import UIKit
import Core

/// 마이페이지 > 회원 탈퇴.
///
/// 탈퇴 전에 아쉬웠던 점을 한 가지 고르게 하고, '기타'를 골랐을 때만 직접 입력을 받습니다.
final class WithdrawFeedbackViewController: UIViewController, ToolBarDelegate {

    // MARK: - Views
    private let withdrawFeedbackView = WithdrawFeedbackView()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.navigationController?.navigationBar.isHidden = true

        setupView()
        setupActions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
    }

    // MARK: - Setup
    private func setupView() {
        view.addSubview(withdrawFeedbackView)
        withdrawFeedbackView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.verticalEdges.equalTo(self.view.safeAreaLayoutGuide)
        }
        withdrawFeedbackView.toolBar.delegate = self
    }

    private func setupActions() {
        withdrawFeedbackView.onWithdrawTap = { [weak self] in
            self?.requestWithdraw()
        }
    }

    // MARK: - Actions
    func leftNaviItemTap() {
        UIDevice.vibrate()
        navigationController?.popViewController(animated: true)
    }

    /// '탈퇴하기' 탭
    private func requestWithdraw() {
        UIDevice.vibrate()
        view.endEditing(true)

        guard let reason = withdrawFeedbackView.selectedReason else { return }
        let detail = withdrawFeedbackView.detailText()

        // TODO: 탈퇴 사유를 함께 보내는 탈퇴 API 연동
        // 연동할 때는 아래 순서로 처리합니다.
        //  1) 선택한 사유(reason)와 '기타'일 때의 직접 입력(detail)을 담아 탈퇴 API 호출
        //  2) NotificationCenter.default.post(name: .SignOut, object: nil)
        //  3) SnackBar.shared.show(type: .deleteUser)
        //  4) AnalyticsManager.shared.log(.withdraw) / AnalyticsManager.shared.setUserID(nil)
        print("회원탈퇴 요청 - 사유: \(reason), 직접 입력: \(detail ?? "-")")
    }
}
