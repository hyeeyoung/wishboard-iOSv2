//
//  TermsLabel.swift
//  WishboardV2
//
//  Created by gomin on 3/5/25.
//

import Foundation
import UIKit
import Core

class TermsLabel: UILabel {

    var onTapTerms: (() -> Void)?
    var onTapPrivacy: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLabel()
        setupGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLabel() {
        let fullText = "가입 시 이용약관 및 개인정보 처리방침에 동의하는 것으로 간주합니다."
        let termsText = "이용약관"
        let privacyText = "개인정보 처리방침"

        let attributedString = NSMutableAttributedString(string: fullText, attributes: [
            .font: TypoStyle.SuitD3.font,
            .foregroundColor: UIColor.gray_300
        ])

        // "이용약관" 스타일 설정
        if let termsRange = fullText.range(of: termsText) {
            let nsRange = NSRange(termsRange, in: fullText)
            attributedString.addAttributes([
                .font: TypoStyle.SuitB4.font,
                .foregroundColor: UIColor.green_700,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ], range: nsRange)
        }

        // "개인정보 처리방침" 스타일 설정
        if let privacyRange = fullText.range(of: privacyText) {
            let nsRange = NSRange(privacyRange, in: fullText)
            attributedString.addAttributes([
                .font: TypoStyle.SuitB4.font,
                .foregroundColor: UIColor.green_700,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ], range: nsRange)
        }

        self.attributedText = attributedString
        self.numberOfLines = 0
        self.textAlignment = .center
        self.isUserInteractionEnabled = true
    }

    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.addGestureRecognizer(tapGesture)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let text = self.text else { return }

        let termsRange = (text as NSString).range(of: "이용약관")
        let privacyRange = (text as NSString).range(of: "개인정보 처리방침")

        let tapLocation = gesture.location(in: self)
        let tapIndex = indexOfAttributedTextCharacterAtPoint(point: tapLocation)

        if NSLocationInRange(tapIndex, termsRange) {
            onTapTerms?()
        } else if NSLocationInRange(tapIndex, privacyRange) {
            onTapPrivacy?()
        }
    }

    private func indexOfAttributedTextCharacterAtPoint(point: CGPoint) -> Int {
        guard let attributedText = self.attributedText else { return NSNotFound }

        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: self.bounds.size)
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = self.numberOfLines
        textContainer.lineBreakMode = self.lineBreakMode

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        let location = point
        let index = layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        return index
    }
}
