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
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = .Suit(size: 24, family: .Bold)
        label.textColor = .gray_700
        label.numberOfLines = 0
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = .gray_300
        label.numberOfLines = 0
        return label
    }()
    
    public let textField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .none
        textField.isSecureTextEntry = true
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
    
    public let timerLabel: UILabel = {
        let label = UILabel()
        label.textColor = .pink_700
        label.font = TypoStyle.SuitD2.font
        label.textAlignment = .center
        return label
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
    private var timer: Timer?
    private var remainingSeconds: Int = 300 // 5분 (300초)
    
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
        self.addSubview(textField)
        textField.addSubview(timerLabel)
        self.addSubview(errorLabel)
        self.addSubview(actionButton)
        self.addSubview(termsLabel)
        
        toolBar.snp.makeConstraints { make in
            make.height.equalTo(42)
            make.top.leading.trailing.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(toolBar.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        textField.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(32)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(42)
        }
        
        timerLabel.snp.makeConstraints { make in
            make.centerY.equalTo(textField)
            make.trailing.equalToSuperview().inset(16)
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
            toolBar.configure(title: "", rightButtonTitle: "2/2단계")
            actionButton.setTitle("로그인하기", for: .normal)
            titleLabel.text = Title.codeInput
            descriptionLabel.text = Message.sendedEmail
            textField.attributedPlaceholder = NSAttributedString(
                string: "인증코드를 입력해 주세요.",
                attributes: [
                    .foregroundColor: UIColor.gray_300
                ]
            )
            textField.clearButtonMode = .never
            errorLabel.text = ErrorMessage.authcode
            termsLabel.isHidden = true
            timerLabel.isHidden = false
            startTimer() // ✅ 타이머 시작
            break
        case .register:
            toolBar.configure(title: "", rightButtonTitle: "2/2단계")
            actionButton.setTitle("가입하기", for: .normal)
            titleLabel.text = Title.passwordInput
            descriptionLabel.text = Message.password
            textField.attributedPlaceholder = NSAttributedString(
                string: "비밀번호를 입력해 주세요.",
                attributes: [
                    .foregroundColor: UIColor.gray_300
                ]
            )
            textField.clearButtonMode = .always
            errorLabel.text = ErrorMessage.password
            termsLabel.isHidden = false
            timerLabel.isHidden = true
            break
        }
        descriptionLabel.setTypoStyleWithMultiLine(typoStyle: .SuitD2)
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

// MARK: - Timer Functions
extension PasswordInputView {
    private func startTimer() {
        timer?.invalidate()
        remainingSeconds = 300 // 5분
        updateTimerLabel()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.remainingSeconds > 0 {
                self.remainingSeconds -= 1
                self.updateTimerLabel()
            } else {
                self.timer?.invalidate()
                self.actionButton.isEnabled = false
                self.actionButton.backgroundColor = .gray_100
            }
        }
    }

    private func resetTimer() {
        timer?.invalidate()
        remainingSeconds = 300
        updateTimerLabel()
        startTimer()
    }

    private func updateTimerLabel() {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        timerLabel.text = String(format: "%d:%02d", minutes, seconds)
    }
}
