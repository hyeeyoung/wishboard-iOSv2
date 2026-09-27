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
