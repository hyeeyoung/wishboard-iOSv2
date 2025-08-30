//
//  ModifyProfileView.swift
//  WishboardV2
//
//  Created by gomin on 9/1/24.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core

final class ModifyProfileView: UIView {
    
    // MARK: - Views
    public let toolbar = ToolBar()
    
    public let profileImgView = UIImageView().then {
        $0.image = Image.defaultProfile
        $0.contentMode = .scaleAspectFill
        $0.layer.cornerRadius = 53
        $0.clipsToBounds = true
        $0.isUserInteractionEnabled = true
    }
    public let icon = UIButton().then {
        $0.setImage(Image.cameraGray, for: .normal)
    }
    private let nicknameLabel = UILabel().then {
        $0.text = "닉네임"
        $0.font = TypoStyle.SuitB3.font
        $0.textColor = .gray_700
    }
    
    public let nameTextField = UITextField().then {
        $0.placeholder = "닉네임을 입력해 주세요."
        $0.backgroundColor = .gray_50
        $0.font = TypoStyle.SuitD1.font
        $0.layer.cornerRadius = 6
        $0.setLeftPaddingPoints(12)
        $0.autocapitalizationType = .none
        $0.autocorrectionType = .no
        $0.clearButtonMode = .whileEditing
        $0.becomeFirstResponder()
        $0.spellCheckingType = .no
    }
    
    private let textFieldCountLabel = UILabel().then {
        $0.font = TypoStyle.SuitD3.font
        $0.textColor = .gray_200
    }
    
    public let errorMessageLabel = UILabel().then {
        $0.text = ErrorMessage.existingNickName
        $0.setTypoStyleWithSingleLine(typoStyle: .SuitD3)
        $0.textAlignment = .left
        $0.textColor = .pink_700
        $0.isHidden = true
    }
    
    public lazy var actionButton = AnimatedButton().then {
        $0.setTitle("완료", for: .normal)
        $0.layer.cornerRadius = 12
        $0.setTitleColor(.gray_300, for: .normal)
        $0.titleLabel?.font = TypoStyle.SuitH3.font
        $0.backgroundColor = .gray_100
        $0.isEnabled = false
    }
    
    
    // MARK: - Initializers
    
    var prevNameInput: String = ""
    var viewModel: ModifyProfileViewModel?
    var completeAction: ((UIImage?, String?) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        setupNotificationObservers()
        
        nameTextField.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        nameTextField.delegate = self
        
        nameTextField.attributedPlaceholder = NSAttributedString(
            string: "닉네임을 입력해 주세요.",
            attributes: [
                .foregroundColor: UIColor.gray_300
            ]
        )
    }
    
    convenience init(_ currentProfileImgUrl: String?, _ currentNickname: String?) {
        self.init()
        
        if let currentProfileImgUrl = currentProfileImgUrl {
            self.profileImgView.loadImage(from: currentProfileImgUrl, placeholder: Image.defaultProfile)
        }
        if let currentNickname = currentNickname, !(currentNickname.isEmpty) {
            self.nameTextField.text = currentNickname
            self.actionButton.isEnabled = false
            self.prevNameInput = currentNickname
            self.updateCountLabel(currentNickname)
        }
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
        addSubview(profileImgView)
        addSubview(icon)
        addSubview(nicknameLabel)
        addSubview(nameTextField)
        addSubview(textFieldCountLabel)
        addSubview(errorMessageLabel)
        addSubview(actionButton)
    }
    
    private func setupConstraints() {
        toolbar.configure(title: "프로필 수정")
        
        profileImgView.snp.makeConstraints { make in
            make.top.equalTo(toolbar.snp.bottom).offset(32)
            make.width.height.equalTo(106)
            make.centerX.equalToSuperview()
        }
        
        icon.snp.makeConstraints { make in
            make.width.equalTo(30)
            make.height.equalTo(25)
            make.trailing.equalTo(profileImgView.snp.trailing).offset(6)
            make.bottom.equalTo(profileImgView.snp.bottom).offset(-5)
        }
        
        nicknameLabel.snp.makeConstraints { make in
            make.top.equalTo(profileImgView.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        nameTextField.snp.makeConstraints { make in
            make.top.equalTo(nicknameLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(42)
        }
        
        textFieldCountLabel.snp.makeConstraints { make in
            make.top.equalTo(nameTextField.snp.bottom).offset(2)
            make.trailing.equalTo(nameTextField)
        }
        
        errorMessageLabel.snp.makeConstraints { make in
            make.top.equalTo(nameTextField.snp.bottom).offset(6)
            make.leading.equalTo(nameTextField)
            make.trailing.lessThanOrEqualTo(textFieldCountLabel.snp.leading)
        }
        
        actionButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
            make.bottom.equalTo(self.safeAreaLayoutGuide).offset(-16)
        }
    }
    
    // MARK: - Actions
    
    @objc private func textFieldEditingChanged(_ textField: UITextField) {
        self.errorMessageLabel.isHidden = true
        // 유저의 닉네임 입력값이 변경되었다면 버튼 활성화
        // 유저의 기존 닉네임 그대로라면 버튼 비활성화
        guard let text = textField.text else { return }
        viewModel?.profileNameChanged = (text != self.prevNameInput)
        updateLoginButtonState()
    }
    
    @objc private func actionButtonTapped() {
        UIDevice.vibrate()
        var inputData: (UIImage?, String?) = (self.profileImgView.image, self.nameTextField.text)
        self.completeAction?(inputData.0, inputData.1)
    }
    
    // MARK: - Public Methods
    public func setBackButtonAction(_ delegate: ToolBarDelegate) {
        toolbar.delegate = delegate
    }
    
    public func updateLoginButtonState(_ isEnabled: Bool? = nil) {
        if let isEnabled = isEnabled {
            actionButton.isEnabled = isEnabled
            return
        }
        if let nameInput = nameTextField.text {
            if viewModel!.profileNameChanged || viewModel!.profileImageChanged {
                actionButton.isEnabled = !(nameInput.isEmpty)
            } else {
                actionButton.isEnabled = false
            }
        } else {
            actionButton.isEnabled = false
        }
    }
    
    private func updateCountLabel(_ text: String) {
        let nicknameTextCount = text.count
        textFieldCountLabel.text = "(\(nicknameTextCount)/10)자"
    }
    
    // MARK: - Keyboard
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardFrame.height
            
            actionButton.snp.updateConstraints { make in
                make.bottom.equalTo(super.safeAreaLayoutGuide).offset(-keyboardHeight + 16)
            }
            
            UIView.animate(withDuration: 0.3) {
                self.layoutIfNeeded()
            }
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        actionButton.snp.updateConstraints { make in
            make.bottom.equalTo(super.safeAreaLayoutGuide).offset(-16)
        }
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }
}

// MARK: - UITextFieldDelegate
extension ModifyProfileView: UITextFieldDelegate {
    public func textField(_ textField: UITextField,
                          shouldChangeCharactersIn range: NSRange,
                          replacementString string: String) -> Bool {
        // 현재 텍스트
        let currentText = textField.text ?? ""
        // 바뀔 텍스트
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        // 10자 초과 불가
        if updatedText.count > 10 {
            return false
        } else {
            // 카운트 라벨 업데이트
            updateCountLabel(updatedText)
            return true
        }
    }
}
