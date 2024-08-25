//
//  FolderBottomSheet.swift
//  WishboardV2
//
//  Created by gomin on 8/18/24.
//

import Foundation
import UIKit
import SnapKit
import Then
import Combine

import Core
import WBNetwork

final class FolderBottomSheet: UIView {
    
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
        $0.placeholder = "폴더명을 입력해주세요."
        $0.font = TypoStyle.SuitD1.font
        $0.backgroundColor = .gray_50
        $0.layer.cornerRadius = 6
        $0.setLeftPaddingPoints(12)
        $0.clipsToBounds = true
    }
    private let textCountLabel = UILabel().then {
        $0.text = "(0/10)자"
        $0.font = TypoStyle.SuitD3.font
        $0.textColor = .gray_200
        $0.textAlignment = .right
    }
    private let errorMessageLabel = UILabel().then {
        $0.font = TypoStyle.SuitD3.font
        $0.textColor = .pink_700
        $0.isHidden = true
    }
    private let actionButton = UIButton(type: .system).then {
        $0.setTitle("추가", for: .normal)
        $0.backgroundColor = .gray_100
        $0.setTitleColor(.gray_300, for: .normal)
        $0.titleLabel?.font = TypoStyle.SuitH3.font
        $0.layer.cornerRadius = 24
        $0.clipsToBounds = true
    }
    
    // MARK: - Properties
    private var maxTextLength = 10
    private var cancellables = Set<AnyCancellable>()
    
    var onClose: (() -> Void)?
    var onActionButtonTap: ((String, FolderListResponse?) -> Void)?
    private var folder: FolderListResponse?
    
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
    
    // MARK: - Setup View
    private func setupView() {
        backgroundColor = .white
        layer.cornerRadius = 20
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        addSubview(titleLabel)
        addSubview(closeButton)
        addSubview(textField)
        addSubview(textCountLabel)
        addSubview(errorMessageLabel)
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
            make.height.equalTo(48)
        }
        
        textField.snp.makeConstraints { make in
            make.bottom.equalTo(actionButton.snp.top).offset(-80)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(42)
        }
        
        textCountLabel.snp.makeConstraints { make in
            make.top.equalTo(textField.snp.bottom).offset(6)
            make.trailing.equalTo(textField)
        }
        
        errorMessageLabel.snp.makeConstraints { make in
            make.top.equalTo(textField.snp.bottom).offset(6)
            make.leading.equalTo(textField)
            make.trailing.equalTo(textCountLabel.snp.leading)
        }
    }
    
    private func setupTextField() {
        // 텍스트 필드와 기타 UI 요소 설정
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)
    }
    
    // MARK: - Actions
    @objc private func textFieldEditingChanged(_ textField: UITextField) {
        guard let text = textField.text else { return }
        let limitedText = String(text.prefix(maxTextLength))
        textField.text = limitedText
        textCountLabel.text = "(\(limitedText.count)/\(maxTextLength))자"
        updateActionButtonState(isEnabled: limitedText.count >= 1 && limitedText.count <= maxTextLength)
    }
    
    @objc private func closeButtonTapped() {
        onClose?()
    }
    
    @objc private func actionButtonTapped() {
        guard let text = textField.text, !text.isEmpty else {
            displayErrorMessage("폴더명을 입력해주세요.")
            return
        }
        onActionButtonTap?(text, folder)
    }
    
    private func updateActionButtonState(isEnabled: Bool) {
        actionButton.isEnabled = isEnabled
        if isEnabled {
            actionButton.backgroundColor = .green_500
            actionButton.setTitleColor(.gray_700, for: .normal)
        } else {
            actionButton.backgroundColor = .gray_100
            actionButton.setTitleColor(.gray_300, for: .normal)
        }
    }
    
    // MARK: - Public Methods
    func displayErrorMessage(_ message: String) {
        errorMessageLabel.text = message
        errorMessageLabel.isHidden = false
    }
    
    func resetView() {
        textField.text = ""
        textCountLabel.text = "0/\(maxTextLength) 자"
        errorMessageLabel.isHidden = true
    }
    
    func configure(with folder: FolderListResponse?) {
        
        self.snp.makeConstraints { make in
            make.height.equalToSuperview().multipliedBy(0.4)
        }
        
        self.folder = folder
        if let folder = folder {
            titleLabel.text = "폴더명 수정"
            textField.text = folder.folder_name
        } else {
            titleLabel.text = "새 폴더 추가"
            textField.text = ""
        }
        textCountLabel.text = "\(textField.text?.count ?? 0)/\(maxTextLength) 자"
        errorMessageLabel.isHidden = true
    }
}

// MARK: - TextField Delegate
extension FolderBottomSheet: UITextFieldDelegate {
    // UITextFieldDelegate 메서드
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
        return newText.count <= maxTextLength // 글자 수 제한
    }
}
