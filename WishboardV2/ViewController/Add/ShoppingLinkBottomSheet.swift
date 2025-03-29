//
//  ShoppingLinkBottomSheet.swift
//  WishboardV2
//
//  Created by gomin on 2/23/25.
//

import Foundation
import UIKit
import SnapKit
import Then
import Combine

import Core
import WBNetwork

final class ShoppingLinkBottomSheet: UIView {
    
    // MARK: - UI Components
    private let titleLabel = UILabel().then {
        $0.text = "Title"
        $0.font = TypoStyle.SuitH3.font
        $0.textAlignment = .center
    }
    private let closeButton = UIButton(type: .system).then {
        $0.setImage(Image.quit, for: .normal)
        $0.tintColor = .gray_700
    }
    private let textField = UITextField().then {
        $0.placeholder = Placeholder.shoppingLink
        $0.font = TypoStyle.SuitD1.font
        $0.backgroundColor = .gray_50
        $0.layer.cornerRadius = 6
        $0.setLeftPaddingPoints(12)
        $0.clipsToBounds = true
        $0.autocorrectionType = .no
        $0.autocapitalizationType = .none
        $0.clearButtonMode = .always
        $0.spellCheckingType = .no
    }
    private let errorLabel = UILabel().then {
        $0.text = ErrorMessage.shoppingLink
        $0.font = TypoStyle.SuitD3.font
        $0.textAlignment = .left
        $0.textColor = .pink_700
        $0.isHidden = true
    }
    private let actionButton = AnimatedButton().then {
        $0.setTitle("완료", for: .normal)
        $0.backgroundColor = .gray_100
        $0.setTitleColor(.gray_300, for: .normal)
        $0.titleLabel?.font = TypoStyle.SuitH3.font
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
    }
    
    // MARK: - Properties
    private var cancellables = Set<AnyCancellable>()
    public var prevLink: String?
    
    var onClose: (() -> Void)?
    var onActionButtonTap: ((String?) -> Void)?
    
    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
        setupTextField()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        removeObservers()
    }
    
    // MARK: - Setup View
    private func setupView() {
        backgroundColor = .white
        layer.cornerRadius = 20
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        addSubview(titleLabel)
        addSubview(closeButton)
        addSubview(textField)
        addSubview(errorLabel)
        addSubview(actionButton)
        
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.centerX.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        actionButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-34)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        
        textField.snp.makeConstraints { make in
            make.bottom.equalTo(actionButton.snp.top).offset(-80)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(42)
        }
        
        errorLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(textField)
            make.top.equalTo(textField.snp.bottom).offset(6)
        }
    }
    
    private func setupTextField() {
        // 텍스트 필드와 기타 UI 요소 설정
        textField.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)
    }
    
    // MARK: - Actions
    @objc private func textFieldEditingChanged(_ textField: UITextField) {
        guard let text = textField.text else { return }
        errorLabel.isHidden = true
        updateActionButtonState(isEnabled: text.count >= 1)
    }
    
    @objc private func closeButtonTapped() {
        self.endEditing(true)
        self.removeObservers()
        onClose?()
    }
    
    @objc private func actionButtonTapped() {
        self.endEditing(true)
        guard let text = textField.text, !text.isEmpty else { return }
        
        // 유효하지 않은 링크 예외처리
        guard let url = URL(string: text), ["http", "https"].contains(url.scheme?.lowercased()) else {
            errorLabel.isHidden = false
            updateActionButtonState(isEnabled: false)
            return
        }
        onActionButtonTap?(text)
        self.removeObservers()
    }
    
    @objc func dismissKeyboard() {
        self.endEditing(true)
    }
    
    private func updateActionButtonState(isEnabled: Bool) {
        actionButton.isEnabled = isEnabled
    }
    
    // MARK: - Public Methods
    
    func initView() {
//        self.setUpObservers()
        self.isHidden = false
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.addGestureRecognizer(tapGesture)
    }
    
    func resetView() {
        textField.text = ""
        self.updateActionButtonState(isEnabled: false)
        self.removeObservers()
        self.isHidden = true
    }
    
    func configure(with prevLink: String? = nil) {
        setUpObservers()
        
        self.snp.makeConstraints { make in
            make.height.equalToSuperview().multipliedBy(0.4)
        }
        
        titleLabel.text = Title.shoppingLinkBottomSheet
        textField.text = prevLink
        self.updateActionButtonState(isEnabled: (prevLink != nil))
    }
}

// MARK: - TextField Delegate

// MARK: - Keyboard Event
extension ShoppingLinkBottomSheet {
    
    // Keyboard Observers
    private func setUpObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    public func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardFrame.height
            UIView.animate(withDuration: 0.3) {
                self.snp.updateConstraints { make in
                    make.bottom.equalToSuperview().offset(-keyboardHeight)
                }
                self.layoutIfNeeded()
            }
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.3) {
            self.snp.updateConstraints { make in
                make.bottom.equalToSuperview()
            }
            self.layoutIfNeeded()
        }
    }
}
