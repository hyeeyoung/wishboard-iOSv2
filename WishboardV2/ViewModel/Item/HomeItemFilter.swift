//
//  HomeItemFilter.swift
//  WishboardV2
//
//  Created by gomin on 10/9/26.
//

import Foundation
import WBNetwork

/// 홈화면 아이템 목록의 필터.
///
/// 조회 API의 `itemStatus` 파라미터로 그대로 동작하며, 값을 보내지 않으면 전체 조회가 됩니다.
enum HomeItemFilter: CaseIterable {
    case all
    case ownedOnly
    case wishOnly

    /// 스티키 헤더의 딱지에 노출되는 문구
    var chipTitle: String {
        switch self {
        case .all:       return "전체"
        case .ownedOnly: return "소장템만"
        case .wishOnly:  return "위시템만"
        }
    }

    /// 필터 선택 바텀시트에 노출되는 문구
    var listTitle: String {
        switch self {
        case .all:       return "전체 보기"
        case .ownedOnly: return "소장템만 보기"
        case .wishOnly:  return "위시템만 보기"
        }
    }

    /// 목록 조회에 넘기는 상태 파라미터. 전체 보기는 값을 보내지 않습니다.
    var itemStatus: ItemStatusType? {
        switch self {
        case .all:       return nil
        case .ownedOnly: return .owned
        case .wishOnly:  return .wish
        }
    }
}
