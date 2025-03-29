//
//  ModifyPasswordView.swift
//  WishboardV2
//
//  Created by gomin on 9/7/24.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core

final class ModifyPasswordView: UIView {
    
    // MARK: - Views
    private let toolbar = ToolBar()
    
    private let newPasswordLabel = UILabel().then {
        $0.text = Title.newPassword
        $0.font = TypoStyle.SuitB3.font
        $0.textColor = .gray_700
    }
    
    public let newPasswordTextField = UITextField().then {
        $0.placeholder = Placeholder.newPassword
        $0.backgroundColor = .gray_50
        $0.font = TypoStyle.SuitD1.font
        $0.layer.cornerRadius = 6
        $0.setLeftPaddingPoints(12)
        $0.isSecureTextEntry = true
        $0.autocapitalizationType = .none
        $0.autocorrectionType = .no
        $0.spellCheckingType = .no
    }
    
    public let newPasswordErrorLabel = UILabel().then {
        $0.text = ErrorMessage.password
        $0.font = TypoStyle.SuitD3.font
        $0.textColor = .pink_700
        $0.isHidden = true
    }
    
    private let repeatLabel = UILabel().then {
        $0.text = Title.passwordRewrite
        $0.font = TypoStyle.SuitB3.font
        $0.textColor = .gray_700
    }
    
    public let repeatTextField = UITextField().then {
        $0.placeholder = Placeholder.rewritePassword
        $0.backgroundColor = .gray_50
        $0.font = TypoStyle.SuitD1.font
        $0.layer.cornerRadius = 6
        $0.setLeftPaddingPoints(12)
        $0.isSecureTextEntry = true
        $0.autocapitalizationType = .none
        $0.autocorrectionType = .no
        $0.spellCheckingType = .no
    }
    
    public let repeatErrorLabel = UILabel().then {
        $0.text = ErrorMessage.passwordRewrite
        $0.font = TypoStyle.SuitD3.font
        $0.textColor = .pink_700
        $0.isHidden = true
    }
    
    public lazy var completeButton = AnimatedButton().then {
        $0.setTitle("완료", for: .normal)
        $0.layer.cornerRadius = 12
        $0.setTitleColor(.gray_300, for: .normal)
        $0.titleLabel?.font = TypoStyle.SuitH3.font
        $0.backgroundColor = .gray_100
        $0.isEnabled = false
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
        addSubview(newPasswordLabel)
        addSubview(newPasswordTextField)
        addSubview(newPasswordErrorLabel)
        addSubview(repeatLabel)
        addSubview(repeatTextField)
        addSubview(repeatErrorLabel)
        addSubview(completeButton)
    }
    
    private func setupConstraints() {
        toolbar.configure(title: "비밀번호 변경")
        
        newPasswordLabel.snp.makeConstraints { make in
            make.top.equalTo(toolbar.snp.bottom).offset(32)
            make.leading.equalToSuperview().offset(16)
        }
        
        newPasswordTextField.snp.makeConstraints { make in
            make.top.equalTo(newPasswordLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(42)
        }
        
        newPasswordErrorLabel.snp.makeConstraints { make in
            make.top.equalTo(newPasswordTextField.snp.bottom).offset(6)
            make.leading.equalTo(newPasswordTextField)
        }
        
        repeatLabel.snp.makeConstraints { make in
            make.top.equalTo(newPasswordErrorLabel.snp.bottom).offset(32)
            make.leading.equalToSuperview().offset(16)
        }
        
        repeatTextField.snp.makeConstraints { make in
            make.top.equalTo(repeatLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(42)
        }
        
        repeatErrorLabel.snp.makeConstraints { make in
            make.top.equalTo(repeatTextField.snp.bottom).offset(6)
            make.leading.equalTo(repeatTextField)
        }
        
        completeButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
            make.bottom.equalTo(self.safeAreaLayoutGuide).offset(-16)
        }
    }
    
    // MARK: - Public Methods
    public func setBackButtonAction(_ delegate: ToolBarDelegate) {
        toolbar.delegate = delegate
    }
    
    public func updateLoginButtonState(isEnabled: Bool) {
        completeButton.isEnabled = isEnabled
    }
    
    // MARK: - Keyboard
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardFrame.height
            
            completeButton.snp.updateConstraints { make in
                make.bottom.equalTo(super.safeAreaLayoutGuide).offset(-keyboardHeight + 16)
            }
            
            UIView.animate(withDuration: 0.3) {
                self.layoutIfNeeded()
            }
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        completeButton.snp.updateConstraints { make in
            make.bottom.equalTo(super.safeAreaLayoutGuide).offset(-16)
        }
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }
}
