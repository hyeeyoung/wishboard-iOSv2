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
    
    public let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.loveLetter
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
    
    public let emailTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .none
        textField.placeholder = "이메일을 입력해 주세요."
        textField.keyboardType = .emailAddress
        textField.setLeftPaddingPoints(16)
        textField.layer.cornerRadius = 6
        textField.backgroundColor = .gray_50
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.spellCheckingType = .no
        return textField
    }()
    
    public let errorLabel: UILabel = {
        let label = UILabel()
        label.text = "올바른 이메일 형식이 아닙니다."
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
        self.addSubview(imageView)
        self.addSubview(descriptionLabel)
        self.addSubview(emailTextField)
        self.addSubview(errorLabel)
        self.addSubview(actionButton)
        
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
        
        emailTextField.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(32)
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
    }
    
    private func addTargets() {
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
    }
    
    public func configure(type: InputType) {
        self.type = type
        switch type {
        case .emailLogin:
            toolBar.configure(title: "이메일로 로그인하기", rightButtonTitle: "1/2단계")
            actionButton.setTitle("인증메일 받기", for: .normal)
            descriptionLabel.text = "가입하신 이메일을 입력해주세요!\n로그인을 위해 인증코드가 포함된 이메일을 보내드려요."
            break
        case .register:
            toolBar.configure(title: "가입하기", rightButtonTitle: "1/2단계")
            actionButton.setTitle("다음", for: .normal)
            descriptionLabel.text = "이메일 인증으로 비밀번호를 찾을 수 있어요.\n실제 사용될 이메일로 입력해주세요! "
            break
        }
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
        self.errorLabel.text = "앗, 가입되지 않은 계정이에요! 가입하기부터 진행해 주세요."
        self.errorLabel.isHidden = false
    }
    
    /// 올바른 이메일 형식이 아님
    public func showInvalidEmail() {
        self.errorLabel.text = "올바른 이메일 형식이 아닙니다."
        self.errorLabel.isHidden = false
    }
    
    /// 이미 가입된 유저
    public func showDuplicateUser() {
        self.errorLabel.text = "앗, 이미 가입된 계정이에요! 로그인으로 진행해 주세요."
        self.errorLabel.isHidden = false
    }
    
}
