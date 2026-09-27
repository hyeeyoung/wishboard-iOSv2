//
//  String.swift
//  Wishboard
//
//  Created by gomin on 2022/09/06.
//

import Foundation

extension String {
    func checkEmail() -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        return  NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: self)
    }
    func checkPassword() -> Bool {
        let regex = "^(?=.*[A-Za-z])(?=.*[0-9])(?=.*[!@#$%^&*()_+=-]).{8,50}" // 8자리 ~ 50자리 영어+숫자+특수문자
        return  NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: self)
    }
    /// 아이템 파싱에 쓸 수 있는 쇼핑몰 링크 형식인지 검사합니다.
    /// 쇼핑몰 링크 시트, 클립보드 불러오기, 링크 공유가 같은 기준을 쓰도록 여기에 둡니다.
    ///
    /// http/https 여부만 보면 `http://zzz` 처럼 호스트가 도메인 꼴이 아닌 값도 통과하므로,
    /// 호스트가 실제 도메인 형식인지까지 확인합니다.
    public func isValidShoppingLink() -> Bool {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty,
              let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = url.host
        else { return false }

        return host.isDomainFormattedHost()
    }

    /// 텍스트에서 쇼핑몰 링크로 쓸 수 있는 첫 번째 URL을 찾아 돌려줍니다.
    ///
    /// 다른 앱에서 링크를 복사하거나 공유하면 안내 문구가 함께 담기는 경우가 많습니다.
    /// 그런 경우 문자열 전체는 URL이 아니므로, 본문에서 링크만 뽑아냅니다.
    ///
    /// 매치된 원문을 그대로 쓰고 `NSDataDetector`가 붙여 주는 스킴은 쓰지 않습니다.
    /// 본문에 섞인 `www.foo.com`이나 맨 도메인까지 링크로 집지 않기 위해서입니다.
    public func firstShoppingLink() -> String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // 문자열 자체가 링크라면 굳이 본문을 훑지 않습니다.
        if trimmed.isValidShoppingLink() { return trimmed }

        guard let detector = try? NSDataDetector(
            types: NSTextCheckingResult.CheckingType.link.rawValue
        ) else { return nil }

        let fullRange = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)

        for match in detector.matches(in: trimmed, options: [], range: fullRange) {
            guard let matchRange = Range(match.range, in: trimmed) else { continue }

            let candidate = String(trimmed[matchRange])
            // 스킴이 없는 매치는 여기서 걸러집니다.
            guard candidate.isValidShoppingLink() else { continue }

            return candidate
        }

        return nil
    }

    /// 호스트가 도메인 형식인지 검사합니다.
    ///
    /// - 점으로 구분된 라벨이 둘 이상이어야 합니다. (`zzz` 같은 단일 라벨은 거부)
    /// - 마지막 라벨(TLD)은 영문 2자 이상이어야 합니다. (IP 주소, `example.1` 등은 거부)
    /// - 각 라벨은 비어 있지 않고, 영숫자와 하이픈만 쓰며, 하이픈으로 시작하거나 끝나지 않습니다.
    ///
    /// 이미 `URL`로 만들어진 값은 문자열로 되돌려 다시 파싱하지 않고 호스트만 이 메서드로 검사합니다.
    public func isDomainFormattedHost() -> Bool {
        let labels = split(separator: ".", omittingEmptySubsequences: false)

        guard labels.count >= 2,
              let tld = labels.last,
              tld.count >= 2,
              tld.allSatisfy({ $0.isLetter })
        else { return false }

        return labels.allSatisfy { label in
            !label.isEmpty
                && label.first != "-"
                && label.last != "-"
                && label.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" }
        }
    }
}
