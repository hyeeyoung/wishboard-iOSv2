//
//  EditPillButton.swift
//  WishboardV2
//
//  Created by gomin on 9/25/26.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core

/// '편집' / '저장' 처럼 짧은 텍스트를 담는 알약 모양 버튼.
///
/// 마이페이지 프로필 섹션과 아이템 상세 메모 섹션이 같은 모양을 써야 해서
/// 한 곳에서 정의합니다.
final class EditPillButton: UIButton {

    /// 버튼 스타일. 텍스트 컬러와 배경색만 다릅니다.
    enum Style {
        /// 편집 진입 (회색 배경)
        case edit
        /// 편집 중 저장 (진회색 배경)
        case save

        var titleColor: UIColor {
            switch self {
            case .edit: return .gray_600
            case .save: return .white_10
            }
        }

        var backgroundColor: UIColor {
            switch self {
            case .edit: return .gray_100
            case .save: return .gray_700
            }
        }
    }

    /// 텍스트와 알약 배경 사이 여백
    private static let contentInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
    private static let cornerRadius: CGFloat = 12

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        clipsToBounds = true
        layer.cornerRadius = EditPillButton.cornerRadius
    }

    /// 텍스트와 스타일을 함께 지정합니다.
    func configure(title: String, style: Style) {
        setTitle(title, for: .normal)
        setTitleColor(style.titleColor, for: .normal)
        backgroundColor = style.backgroundColor

        // setTitle이 attributedText를 새로 만들기 때문에 타이포 적용은 항상 그 뒤에 합니다.
        titleLabel?.setTypoStyleWithSingleLine(typoStyle: .SuitB3)
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        let titleSize = titleLabel?.intrinsicContentSize ?? .zero
        return CGSize(
            width: titleSize.width + EditPillButton.contentInsets.left + EditPillButton.contentInsets.right,
            height: titleSize.height + EditPillButton.contentInsets.top + EditPillButton.contentInsets.bottom
        )
    }
}
