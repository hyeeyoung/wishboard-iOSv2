//
//  BannerSupport.swift
//  WishboardV2
//
//  Created by gomin on 11/24/26.
//

import UIKit

extension UIColor {

    /// 서버가 내려주는 배너 색상 문자열을 읽습니다.
    ///
    /// **알파가 앞 2자리입니다** (`#AARRGGBB`). 안드로이드 `Color.parseColor` 와 같은 순서라,
    /// iOS 에서 흔히 쓰는 `#RRGGBBAA` 와 반대입니다. 6자리로 오면 불투명으로 봅니다.
    ///
    /// - Returns: 형식이 맞지 않으면 nil. 호출하는 쪽에서 기본 색으로 넘어갑니다.
    convenience init?(argbHexString: String?) {
        guard let raw = argbHexString?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else { return nil }

        let hex = raw.hasPrefix("#") ? String(raw.dropFirst()) : raw
        guard hex.count == 6 || hex.count == 8,
              hex.allSatisfy({ $0.isHexDigit }),
              let value = UInt64(hex, radix: 16) else { return nil }

        let alpha: CGFloat
        let rgb: UInt64

        if hex.count == 8 {
            alpha = CGFloat((value >> 24) & 0xFF) / 255
            rgb = value & 0x00FF_FFFF
        } else {
            alpha = 1
            rgb = value
        }

        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: alpha
        )
    }
}

/// 사용자가 닫은 배너를 기억합니다.
///
/// 서버에 보내지 않고 기기에만 남기며, 앱을 지우면 함께 사라집니다.
/// 같은 배너를 다시 띄우고 싶을 때 서버는 새 id 로 등록하므로 여기에 걸리지 않습니다.
enum BannerDismissStore {

    private static let key = "dismissedBannerIds"

    /// 기록이 무한정 늘지 않도록 최근 것만 남깁니다.
    private static let limit = 200

    static func dismissedIds() -> Set<Int> {
        let ids = UserDefaults.standard.array(forKey: key) as? [Int] ?? []
        return Set(ids)
    }

    static func markDismissed(_ id: Int) {
        var ids = UserDefaults.standard.array(forKey: key) as? [Int] ?? []
        guard !ids.contains(id) else { return }

        ids.append(id)
        if ids.count > limit {
            ids.removeFirst(ids.count - limit)
        }
        UserDefaults.standard.set(ids, forKey: key)
    }
}
