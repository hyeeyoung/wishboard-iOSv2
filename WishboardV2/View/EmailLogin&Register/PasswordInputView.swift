//
//  PasswordInputView.swift
//  WishboardV2
//
//  Created by gomin on 3/5/25.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core

final class PasswordInputView: UIView {
    // MARK: - Views
    public let toolBar = InputToolBar()
    
    public let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.locked
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = TypoStyle.SuitD2.font
        label.textColor = .gray_700
        label.numberOfLines = 0
        return label
    }()
    
    public let textField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .none
        textField.placeholder = "이메일을 입력해 주세요."
        textField.isSecureTextEntry = true
        textField.setLeftPaddingPoints(16)
        textField.layer.cornerRadius = 6
        textField.backgroundColor = .gray_50
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        return textField
    }()
    
    public let errorLabel: UILabel = {
        let label = UILabel()
        label.textColor = .pink_700
        label.font = TypoStyle.SuitD3.font
        label.isHidden = true
        return label
    }()
    
    public let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = TypoStyle.SuitH3.font
        button.setTitleColor(.gray_200, for: .disabled)
        button.setTitleColor(.gray_700, for: .normal)
        button.backgroundColor = .gray_100
        button.layer.cornerRadius = 12
        button.isEnabled = false
        return button
    }()
    
    public let termsLabel = TermsLabel()
    
    // MARK: - Properties
    private var type: InputType?
    public var emailLoginAction: ((String?) -> Void)?
    public var registerAction: ((String?) -> Void)?
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupViews()
        addTargets()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    private func setupViews() {
        self.addSubview(toolBar)
        self.addSubview(imageView)
        self.addSubview(descriptionLabel)
        self.addSubview(textField)
        self.addSubview(errorLabel)
        self.addSubview(actionButton)
        self.addSubview(termsLabel)
        
        toolBar.snp.makeConstraints { make in
            make.height.equalTo(42)
            make.top.leading.trailing.equalToSuperview()
        }
        
        imageView.snp.makeConstraints { make in
            make.top.equalTo(toolBar.snp.bottom).offset(14)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(72)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(36)
        }
        
        textField.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(32)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(42)
        }
        
        errorLabel.snp.makeConstraints { make in
            make.top.equalTo(textField.snp.bottom).offset(6)
            make.leading.equalTo(textField)
        }
        
        actionButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(50)
            make.bottom.equalTo(super.safeAreaLayoutGuide).inset(16)
        }
        
        termsLabel.snp.makeConstraints { make in
            make.bottom.equalTo(actionButton.snp.top).offset(-6)
            make.leading.trailing.equalToSuperview().inset(22.5)
        }
    }
    
    private func addTargets() {
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
    }
    
    public func configure(type: InputType) {
        self.type = type
        switch type {
        case .emailLogin:
            toolBar.configure(title: "이메일로 로그인하기", rightButtonTitle: "2/2단계")
            actionButton.setTitle("로그인하기", for: .normal)
            descriptionLabel.text = "인증코드가 전송되었어요!\n이메일을 확인해주세요."
            textField.placeholder = "인증코드를 입력해 주세요."
            errorLabel.text = "인증코드를 다시 확인해 주세요."
            termsLabel.isHidden = true
            break
        case .register:
            toolBar.configure(title: "가입하기", rightButtonTitle: "2/2단계")
            actionButton.setTitle("가입하기", for: .normal)
            descriptionLabel.text = "마지막 비밀번호 입력 단계예요!\n입력된 비밀번호로 바로 가입되니 신중히 입력해 주세요."
            textField.placeholder = "비밀번호를 입력해 주세요."
            errorLabel.text = "8자리 이상의 영문자, 숫자, 특수 문자 조합으로 입력해주세요."
            termsLabel.isHidden = false
            break
        }
    }
    
    @objc private func actionButtonTapped() {
        switch self.type {
        case .emailLogin:
            self.emailLoginAction?(self.textField.text)
            break
        case .register:
            self.registerAction?(self.textField.text)
            break
        default:
            break
        }
    }
    
}
