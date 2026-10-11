//
//  WithdrawalReasonResponse.swift
//  WBNetwork
//
//  Created by gomin on 10/11/26.
//

import Foundation

/// 탈퇴 화면에 노출할 사유 한 건.
///
/// 서버가 내려주는 순서가 곧 화면에 보여 줄 순서입니다.
public struct WithdrawalReasonResponse: Decodable {
    /// 피드백 등록에 보낼 값
    public let code: String?
    /// 화면에 보여 줄 문구
    public let description: String?
    /// 직접 입력이 필요한 항목인지 여부 (기타)
    public let detailRequired: Bool?
}
