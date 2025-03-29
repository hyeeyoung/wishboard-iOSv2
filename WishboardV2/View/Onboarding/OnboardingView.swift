//
//  OnboardingView.swift
//  WishboardV2
//
//  Created by gomin on 7/27/24.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core

final class OnboardingView: UIView {
    
    // MARK: - Views
    // 흔드는 손 Image
    private let handImage = UIImageView().then{
        $0.image = Image.wavingHand
    }
    // Wish Board Logo Image
    private let logoImage = UIImageView().then{
        $0.image = Image.wishboardLogo
    }
    // Onbarding label
    private let onboardingLabel = UILabel().then{
        $0.text = Message.onboarding
        $0.setTypoStyleWithMultiLine(typoStyle: .SuitD2)
        $0.numberOfLines = 0
        $0.textAlignment = .center
    }
    // 가입하기 버튼
    public lazy var registerButton = UIButton().then{
        $0.setTitle(Button.register, for: .normal)
        $0.setTitleColor(.gray_700, for: .normal)
        $0.titleLabel?.font = TypoStyle.SuitH3.font
        $0.backgroundColor = .green_500
        $0.layer.cornerRadius = 12
    }
    
    // 이미 계정이 있으신가요? 로그인
    public let loginLabel = UILabel().then{
        // 이미 계정이 있으신가요?
        let toLoginAttributes: [NSAttributedString.Key: Any] = [
            .font: TypoStyle.SuitD2.font,
            .foregroundColor: UIColor.gray_300
        ]
        // 로그인
        let loginAttributes: [NSAttributedString.Key: Any] = [
            .font: TypoStyle.SuitH4.font,
            .foregroundColor: UIColor.green_700,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.maximumLineHeight = TypoStyle.SuitD2.labelDescription.singleLineHeight
        paragraphStyle.minimumLineHeight = TypoStyle.SuitD2.labelDescription.singleLineHeight
        
        let attributedText = NSMutableAttributedString(string: Message.toLogin, attributes: toLoginAttributes)
        attributedText.addAttributes([.paragraphStyle: paragraphStyle], range: NSRange(location: 0, length: attributedText.length))
        
        paragraphStyle.maximumLineHeight = TypoStyle.SuitH4.labelDescription.singleLineHeight
        paragraphStyle.minimumLineHeight = TypoStyle.SuitH4.labelDescription.singleLineHeight
        
        let loginAttributedText = NSMutableAttributedString(string: " \(Message.login)", attributes: loginAttributes)
        loginAttributedText.addAttributes([.paragraphStyle: paragraphStyle], range: NSRange(location: 0, length: loginAttributedText.length))
        
        attributedText.append(loginAttributedText)
        
        $0.attributedText = attributedText
        $0.numberOfLines = 0
        $0.isUserInteractionEnabled = true
    }
    
    // MARK: - Life Cycles
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Layouts
    private func setupViews() {
        addSubview(logoImage)
        addSubview(handImage)
        addSubview(onboardingLabel)
        addSubview(loginLabel)
        addSubview(registerButton)
    }
    
    private func setupConstraints() {
        self.logoImage.snp.makeConstraints { make in
            make.width.equalTo(192)
            make.height.equalTo(24)
            make.centerX.centerY.equalToSuperview()
        }
        self.handImage.snp.makeConstraints { make in
            make.width.height.equalTo(72)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(logoImage.snp.top).offset(-24)
        }
        self.onboardingLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(logoImage.snp.bottom).offset(16)
        }
        self.loginLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-66)
        }
        self.registerButton.snp.makeConstraints { make in
            make.height.equalTo(50)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(loginLabel.snp.top).offset(-16)
        }
    }
    
    func configure(with viewModel: OnboardingViewModel) {
        // Configure the view with the view model if needed
    }
}
