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

final class ShoppingLinkBottomSheet: UIView, LoadingPresentable {

    /// 바텀시트 높이 비율. 노출/미노출 애니메이션에서도 같은 값을 씁니다.
    static let heightRatio: CGFloat = 0.45
    /// 두 버튼 사이 간격
    private static let buttonSpacing: CGFloat = 13
    private static let buttonHeight: CGFloat = 50

    
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
        // 화면 너비보다 메시지가 길면 여러 줄로 노출합니다.
        $0.numberOfLines = 0
        $0.isHidden = true
    }
    /// 링크를 파싱해 아이템 정보를 불러오는 버튼
    private let parseButton = UIButton(type: .system).then {
        $0.setTitle(Button.parseItem, for: .normal)
        $0.backgroundColor = .white
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.gray_100.cgColor
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
    }
    /// 파싱 없이 링크만 등록하는 버튼
    private let linkOnlyButton = UIButton(type: .system).then {
        $0.setTitle(Button.registerLinkOnly, for: .normal)
        $0.backgroundColor = .green_500
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
    }
    private lazy var buttonStackView = UIStackView(arrangedSubviews: [parseButton, linkOnlyButton]).then {
        $0.axis = .vertical
        $0.spacing = ShoppingLinkBottomSheet.buttonSpacing
    }
    /// 로딩뷰가 덮을 영역. 타이틀과 닫기 버튼은 가리지 않습니다.
    let loadingContainerView = UIView().then {
        $0.isUserInteractionEnabled = false
    }
    
    // MARK: - Properties
    private var cancellables = Set<AnyCancellable>()
    public var prevLink: String?
    
    var onClose: (() -> Void)?
    /// '아이템 정보 불러오기' 탭. 링크를 파싱해 상품 정보를 채웁니다.
    var onParseButtonTap: ((String) -> Void)?
    /// '링크만 등록하기' 탭. 파싱 없이 링크만 등록합니다.
    var onLinkOnlyButtonTap: ((String) -> Void)?
    
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
        addSubview(buttonStackView)
        addSubview(loadingContainerView)

        // 두 버튼은 텍스트 스타일이 같고 배경/테두리만 다릅니다.
        [parseButton, linkOnlyButton].forEach { button in
            [UIControl.State.normal, .disabled].forEach {
                button.setTitleColor(.gray_700, for: $0)
            }
            button.titleLabel?.font = TypoStyle.SuitH3.font
        }

        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        parseButton.addTarget(self, action: #selector(parseButtonTapped), for: .touchUpInside)
        linkOnlyButton.addTarget(self, action: #selector(linkOnlyButtonTapped), for: .touchUpInside)
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
        
        buttonStackView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-34)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        [parseButton, linkOnlyButton].forEach { button in
            button.snp.makeConstraints { make in
                make.height.equalTo(ShoppingLinkBottomSheet.buttonHeight)
            }
        }

        textField.snp.makeConstraints { make in
            make.bottom.equalTo(buttonStackView.snp.top).offset(-48)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(42)
        }

        errorLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(textField)
            make.top.equalTo(textField.snp.bottom).offset(2)
        }

        loadingContainerView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    private func setupTextField() {
        // 텍스트 필드와 기타 UI 요소 설정
        textField.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)
        
        textField.attributedPlaceholder = NSAttributedString(
            string: Placeholder.shoppingLink,
            attributes: [
                .foregroundColor: UIColor.gray_300
            ]
        )
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
    
    @objc private func parseButtonTapped() {
        guard let link = validatedLink() else { return }
        self.endEditing(true)
        onParseButtonTap?(link)
    }

    @objc private func linkOnlyButtonTapped() {
        guard let link = validatedLink() else { return }
        self.endEditing(true)
        onLinkOnlyButtonTap?(link)
        self.removeObservers()
    }

    /// 입력된 링크가 유효하면 돌려주고, 아니면 에러 메시지를 노출합니다.
    private func validatedLink() -> String? {
        guard let text = textField.text, !text.isEmpty else { return nil }

        // 유효하지 않은 링크 예외처리
        guard let url = URL(string: text), ["http", "https"].contains(url.scheme?.lowercased()) else {
            displayError(ErrorMessage.shoppingLink)
            updateActionButtonState(isEnabled: false)
            return nil
        }
        return text
    }
    
    @objc func dismissKeyboard() {
        self.endEditing(true)
    }
    
    private func updateActionButtonState(isEnabled: Bool) {
        parseButton.isEnabled = isEnabled
        linkOnlyButton.isEnabled = isEnabled
        // 비활성 상태에서도 두 버튼의 배경/테두리는 그대로 두고 흐리게만 표시합니다.
        [parseButton, linkOnlyButton].forEach { $0.alpha = isEnabled ? 1.0 : 0.4 }
    }

    /// 입력 필드 하단에 에러 메시지를 노출합니다.
    func displayError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
    }

    /// 아이템 정보 불러오기 실패 메시지를 노출합니다.
    func displayParseError() {
        displayError(ErrorMessage.parseItem)
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
        errorLabel.isHidden = true
        self.updateActionButtonState(isEnabled: false)
        self.removeObservers()
        self.isHidden = true
    }
    
    func configure(with prevLink: String? = nil) {
        setUpObservers()
        
        self.snp.makeConstraints { make in
            make.height.equalToSuperview().multipliedBy(ShoppingLinkBottomSheet.heightRatio)
        }
        
        titleLabel.text = Title.shoppingLinkBottomSheet
        textField.text = prevLink
        errorLabel.isHidden = true
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
