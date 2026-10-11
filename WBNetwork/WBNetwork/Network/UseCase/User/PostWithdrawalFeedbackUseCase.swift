//
//  PostWithdrawalFeedbackUseCase.swift
//  WBNetwork
//
//  Created by gomin on 10/11/26.
//

import Foundation

public protocol PostWithdrawalFeedbackUseCaseInterface {
    func execute(request: WithdrawalFeedbackRequest) async throws -> EmptyResponse
}

/// 탈퇴 피드백 등록. 탈퇴는 이어서 탈퇴 API 를 호출해야 합니다.
public class PostWithdrawalFeedbackUseCase: PostWithdrawalFeedbackUseCaseInterface {
    private let repository: UserRepositoryInterface

    public init(repository: UserRepositoryInterface = UserRepository()) {
        self.repository = repository
    }

    public func execute(request: WithdrawalFeedbackRequest) async throws -> EmptyResponse {
        return try await self.repository.postWithdrawalFeedback(request: request)
    }
}
