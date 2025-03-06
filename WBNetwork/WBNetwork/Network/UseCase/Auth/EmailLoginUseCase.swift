//
//  EmailLoginUseCase.swift
//  WBNetwork
//
//  Created by gomin on 3/6/25.
//

import Foundation

public protocol EmailLoginUseCaseInterface {
    func execute(email: String) async throws -> CommonResponse<EmailLoginResponse>
}

public class EmailLoginUseCase: EmailLoginUseCaseInterface {
    private let repository: AuthRepositoryInterface
    
    public init(repository: AuthRepositoryInterface = AuthRepository()) {
        self.repository = repository
    }
    
    public func execute(email: String) async throws -> CommonResponse<EmailLoginResponse> {
        return try await self.repository.emailLogin(email: email)
    }
}
