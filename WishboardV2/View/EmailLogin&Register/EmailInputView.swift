//
//  EmailInputView.swift
//  WishboardV2
//
//  Created by gomin on 3/4/25.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core

final class EmailInputView: UIView {
    // MARK: - Views
    public let toolBar = InputToolBar()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = .Suit(size: 24, family: .Bold)
        label.textColor = .gray_700
        label.numberOfLines = 0
        label.text = Title.emailInput
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = .gray_300
        label.numberOfLines = 0
        return label
    }()
    
    public let emailTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .none
        textField.placeholder = Placeholder.email
        textField.keyboardType = .emailAddress
        textField.setLeftPaddingPoints(16)
        textField.layer.cornerRadius = 6
        textField.backgroundColor = .gray_50
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.spellCheckingType = .no
        textField.clearButtonMode = .always
        textField.font = TypoStyle.SuitD1.font
        return textField
    }()
    
    public let errorLabel: UILabel = {
        let label = UILabel()
        label.text = "이메일 주소를 정확하게 입력해주세요."
        label.textColor = .pink_700
        label.font = TypoStyle.SuitD3.font
        label.isHidden = true
        return label
    }()
    
    public lazy var actionButton = AnimatedButton().then {
        $0.layer.cornerRadius = 12
        $0.setTitleColor(.gray_300, for: .normal)
        $0.titleLabel?.font = TypoStyle.SuitH3.font
        $0.backgroundColor = .gray_100
        $0.isEnabled = false
    }
    
    // MARK: - Properties
    private var type: InputType?
    public var emailLoginNextAction: ((String?) -> Void)?
    public var registerNextAction: ((String?) -> Void)?
    
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
        self.addSubview(titleLabel)
        self.addSubview(descriptionLabel)
        self.addSubview(emailTextField)
        self.addSubview(errorLabel)
        self.addSubview(actionButton)
        
        toolBar.snp.makeConstraints { make in
            make.height.equalTo(42)
            make.top.leading.trailing.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(toolBar.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(16)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.leading.equalTo(titleLabel)
        }
        
        emailTextField.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(36)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(42)
        }
        
        errorLabel.snp.makeConstraints { make in
            make.top.equalTo(emailTextField.snp.bottom).offset(6)
            make.leading.equalTo(emailTextField)
        }
        
        actionButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(50)
            make.bottom.equalTo(super.safeAreaLayoutGuide).inset(16)
        }
        
        emailTextField.attributedPlaceholder = NSAttributedString(
            string: Placeholder.email,
            attributes: [
                .foregroundColor: UIColor.gray_300
            ]
        )
    }
    
    private func addTargets() {
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
    }
    
    public func configure(type: InputType) {
        self.type = type
        switch type {
        case .emailLogin:
            toolBar.configure(title: "", rightButtonTitle: "1/2단계")
            actionButton.setTitle("인증메일 받기", for: .normal)
            descriptionLabel.text = Message.lostPassword
            break
        case .register:
            toolBar.configure(title: "", rightButtonTitle: "1/2단계")
            actionButton.setTitle("다음", for: .normal)
            descriptionLabel.text = Message.email
            break
        }
        descriptionLabel.setTypoStyleWithMultiLine(typoStyle: .SuitD2)
    }
    
    @objc private func actionButtonTapped() {
        switch self.type {
        case .emailLogin:
            self.emailLoginNextAction?(self.emailTextField.text)
            break
        case .register:
            self.registerNextAction?(self.emailTextField.text)
            break
        default:
            break
        }
    }
    
    /// 존재하지 않는 유저
    public func showInvalidUser() {
        self.errorLabel.text = ErrorMessage.nonExistAccount
        self.errorLabel.isHidden = false
    }
    
    /// 올바른 이메일 형식이 아님
    public func showInvalidEmail() {
        self.errorLabel.text = "이메일 주소를 정확하게 입력해주세요."
        self.errorLabel.isHidden = false
    }
    
    /// 이미 가입된 유저
    public func showDuplicateUser() {
        self.errorLabel.text = ErrorMessage.existAccount
        self.errorLabel.isHidden = false
    }
    
}
