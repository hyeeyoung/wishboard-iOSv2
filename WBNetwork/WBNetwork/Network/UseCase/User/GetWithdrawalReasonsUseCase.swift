//
//  GetWithdrawalReasonsUseCase.swift
//  WBNetwork
//
//  Created by gomin on 10/11/26.
//

import Foundation

public protocol GetWithdrawalReasonsUseCaseInterface {
    func execute() async throws -> [WithdrawalReasonResponse]
}

/// 탈퇴 화면에 노출할 사유 목록 조회
public class GetWithdrawalReasonsUseCase: GetWithdrawalReasonsUseCaseInterface {
    private let repository: UserRepositoryInterface

    public init(repository: UserRepositoryInterface = UserRepository()) {
        self.repository = repository
    }

    public func execute() async throws -> [WithdrawalReasonResponse] {
        return try await self.repository.getWithdrawalReasons()
    }
}
