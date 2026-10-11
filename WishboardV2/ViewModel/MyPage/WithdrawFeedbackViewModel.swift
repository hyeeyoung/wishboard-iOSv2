//
//  WithdrawFeedbackViewModel.swift
//  WishboardV2
//
//  Created by gomin on 10/11/26.
//

import Foundation
import Combine
import WBNetwork

/// 화면에 뿌릴 탈퇴 사유 한 건
struct WithdrawReason {
    /// 피드백 등록에 보낼 값
    let code: String
    /// 화면에 보여 줄 문구
    let title: String
    /// 직접 입력을 받아야 하는 선택지인지 여부
    let needsDetail: Bool
}

final class WithdrawFeedbackViewModel {

    /// 직접 입력란에 받을 수 있는 최대 글자 수
    static let detailTextLimit: Int = 200

    /// 서버가 내려준 순서대로 노출합니다.
    @Published private(set) var reasons: [WithdrawReason] = []
    @Published private(set) var isLoading: Bool = false

    // MARK: - 조회

    /// 탈퇴 사유 목록 조회
    func fetchReasons() async throws {
        isLoading = true
        defer { isLoading = false }

        let usecase = GetWithdrawalReasonsUseCase()
        let response = try await usecase.execute()

        reasons = response.compactMap { reason in
            guard let code = reason.code, let title = reason.description else { return nil }
            return WithdrawReason(code: code,
                                  title: title,
                                  needsDetail: reason.detailRequired ?? false)
        }
    }

    // MARK: - 탈퇴

    /// 피드백을 남기고 탈퇴합니다.
    ///
    /// 피드백 등록이 실패해도 탈퇴는 그대로 진행합니다.
    func withdraw(reason: WithdrawReason, detail: String?) async throws {
        // 직접 입력이 필요한 사유에만 detail 을 담습니다.
        let request = WithdrawalFeedbackRequest(
            reason: reason.code,
            detail: reason.needsDetail ? detail : nil
        )

        do {
            let feedbackUseCase = PostWithdrawalFeedbackUseCase()
            _ = try await feedbackUseCase.execute(request: request)
        } catch {
            // 피드백은 남기지 못해도 탈퇴는 이어서 진행합니다.
        }

        let deleteUseCase = DeleteUserUseCase()
        _ = try await deleteUseCase.execute()
    }
}
