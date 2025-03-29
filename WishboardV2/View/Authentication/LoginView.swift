//
//  LoginView.swift
//  WishboardV2
//
//  Created by gomin on 8/12/24.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core

final class LoginView: UIView {
    
    // MARK: - Views
    private let toolbar = ToolBar()
    
    private let emailLabel = UILabel().then {
        $0.text = "이메일"
        $0.font = TypoStyle.SuitB3.font
        $0.textColor = .gray_700
    }
    
    public let emailTextField = UITextField().then {
        $0.placeholder = "이메일을 입력해 주세요."
        $0.backgroundColor = .gray_50
        $0.font = TypoStyle.SuitD1.font
        $0.layer.cornerRadius = 6
        $0.setLeftPaddingPoints(12)
        $0.autocapitalizationType = .none
        $0.spellCheckingType = .no
    }
    
    private let passwordLabel = UILabel().then {
        $0.text = "비밀번호"
        $0.font = TypoStyle.SuitB3.font
        $0.textColor = .gray_700
    }
    
    public let passwordTextField = UITextField().then {
        $0.placeholder = "비밀번호를 입력해주세요."
        $0.backgroundColor = .gray_50
        $0.font = TypoStyle.SuitD1.font
        $0.layer.cornerRadius = 6
        $0.setLeftPaddingPoints(12)
        $0.isSecureTextEntry = true
        $0.spellCheckingType = .no
    }
    
    public lazy var loginButton = AnimatedButton().then {
        $0.setTitle("로그인하기", for: .normal)
        $0.layer.cornerRadius = 12
        $0.setTitleColor(.gray_300, for: .normal)
        $0.titleLabel?.font = TypoStyle.SuitH3.font
        $0.backgroundColor = .gray_100
        $0.isEnabled = false
    }
    
    public let forgotPasswordLabel = UILabel().then {
        let attributedText = NSMutableAttributedString(string: "비밀번호를 잊으셨나요?")
        attributedText.addAttributes([
            .font: TypoStyle.SuitB3.font,
            .foregroundColor: UIColor.gray_300,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ], range: NSRange(location: 0, length: attributedText.length))
        
        $0.attributedText = attributedText
        $0.textAlignment = .center
        $0.isUserInteractionEnabled = true
    }
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        setupNotificationObservers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupViews() {
        addSubview(toolbar)
        addSubview(emailLabel)
        addSubview(emailTextField)
        addSubview(passwordLabel)
        addSubview(passwordTextField)
        addSubview(loginButton)
        addSubview(forgotPasswordLabel)
    }
    
    private func setupConstraints() {
        toolbar.configure(title: "로그인하기")
        
        emailLabel.snp.makeConstraints { make in
            make.top.equalTo(toolbar.snp.bottom).offset(32)
            make.leading.equalToSuperview().offset(16)
        }
        
        emailTextField.snp.makeConstraints { make in
            make.top.equalTo(emailLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(42)
        }
        
        passwordLabel.snp.makeConstraints { make in
            make.top.equalTo(emailTextField.snp.bottom).offset(32)
            make.leading.equalToSuperview().offset(16)
        }
        
        passwordTextField.snp.makeConstraints { make in
            make.top.equalTo(passwordLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(42)
        }
        
        loginButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
            make.bottom.equalTo(forgotPasswordLabel.snp.top).offset(-16)
        }

        forgotPasswordLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(super.safeAreaLayoutGuide).offset(-16)
        }
    }
    
    // MARK: - Public Methods
    public func setBackButtonAction(_ delegate: ToolBarDelegate) {
        toolbar.delegate = delegate
    }
    
    public func updateLoginButtonState(isEnabled: Bool) {
        loginButton.isEnabled = isEnabled
    }
    
    // MARK: - Keyboard
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardFrame.height
            
            forgotPasswordLabel.snp.updateConstraints { make in
                make.bottom.equalTo(super.safeAreaLayoutGuide).offset(-keyboardHeight + 16)
            }
            loginButton.snp.updateConstraints { make in
                make.bottom.equalTo(forgotPasswordLabel.snp.top).offset(-16)
            }
            
            UIView.animate(withDuration: 0.3) {
                self.layoutIfNeeded()
            }
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        forgotPasswordLabel.snp.updateConstraints { make in
            make.bottom.equalTo(super.safeAreaLayoutGuide).offset(-16)
        }
        loginButton.snp.updateConstraints { make in
            make.bottom.equalTo(forgotPasswordLabel.snp.top).offset(-16)
        }
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }
}
