//
//  WithdrawFeedbackViewController.swift
//  WishboardV2
//
//  Created by gomin on 10/8/26.
//

import Foundation
import UIKit
import Combine
import Core
import ApplicationLibrary

/// 마이페이지 > 회원 탈퇴.
///
/// 탈퇴 전에 아쉬웠던 점을 한 가지 고르게 하고, 직접 입력이 필요한 사유에서만 내용을 받습니다.
final class WithdrawFeedbackViewController: UIViewController, ToolBarDelegate {

    // MARK: - Views
    private let withdrawFeedbackView = WithdrawFeedbackView()

    // MARK: - Properties
    private let viewModel = WithdrawFeedbackViewModel()
    private var cancellables = Set<AnyCancellable>()
    /// 탈퇴 요청이 끝나기 전에 버튼이 다시 눌리는 것을 막습니다.
    private var isWithdrawing = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.navigationController?.navigationBar.isHidden = true

        setupView()
        setupActions()
        setupBindings()

        fetchReasons()
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

    private func setupBindings() {
        viewModel.$reasons
            .receive(on: RunLoop.main)
            .sink { [weak self] reasons in
                self?.withdrawFeedbackView.updateReasons(reasons)
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] isLoading in
                self?.withdrawFeedbackView.setLoading(isLoading)
            }
            .store(in: &cancellables)
    }

    /// 탈퇴 사유 목록 조회
    private func fetchReasons() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                try await self.viewModel.fetchReasons()
            } catch {
                // 실패 토스트는 ErrorPlugin에서 공통 처리합니다.
                // 목록이 없으면 고를 것이 없어 이전 화면으로 돌아갑니다.
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

    // MARK: - Actions
    func leftNaviItemTap() {
        UIDevice.vibrate()
        navigationController?.popViewController(animated: true)
    }

    /// '탈퇴하기' 탭
    ///
    /// 피드백을 먼저 남기고 탈퇴합니다. 피드백이 실패해도 탈퇴는 그대로 진행합니다.
    private func requestWithdraw() {
        guard !isWithdrawing else { return }
        guard let reason = withdrawFeedbackView.selectedReason else { return }

        UIDevice.vibrate()
        view.endEditing(true)
        isWithdrawing = true

        let detail = withdrawFeedbackView.detailText()
        withdrawFeedbackView.showLoading()

        Task { @MainActor [weak self] in
            guard let self = self else { return }

            do {
                try await self.viewModel.withdraw(reason: reason, detail: detail)

                self.withdrawFeedbackView.hideLoading()
                self.isWithdrawing = false
                self.completeWithdraw()
            } catch {
                self.withdrawFeedbackView.hideLoading()
                self.isWithdrawing = false
                // 실패 토스트는 ErrorPlugin에서 공통 처리합니다.
                // 선택 상태는 그대로 두어 다시 시도할 수 있게 합니다.
            }
        }
    }

    /// 탈퇴 성공 후 처리. 기존 탈퇴 흐름과 같습니다.
    private func completeWithdraw() {
        NotificationCenter.default.post(name: .SignOut, object: nil)
        DispatchQueue.main.async {
            SnackBar.shared.show(type: .deleteUser)
        }

        AnalyticsManager.shared.log(.withdraw)
        AnalyticsManager.shared.setUserID(nil)
    }
}
