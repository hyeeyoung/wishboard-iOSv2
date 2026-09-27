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
    /// 두 버튼을 가로로 나란히 배치합니다. (좌: 아이템 정보 불러오기 / 우: 링크만 등록하기)
    private lazy var buttonStackView = UIStackView(arrangedSubviews: [parseButton, linkOnlyButton]).then {
        $0.axis = .horizontal
        $0.distribution = .fillEqually
        $0.spacing = ShoppingLinkBottomSheet.buttonSpacing
    }
    /// 키보드 뒤를 덮는 배경의 높이. 어떤 기기의 키보드보다도 크게 잡아 둡니다.
    private static let keyboardBackdropHeight: CGFloat = 400

    /// 키보드가 올라와 시트가 위로 밀렸을 때, 시트 아래쪽 영역을 시트와 같은 색으로 덮습니다.
    ///
    /// 시트 하단이 키보드 상단에서 딱 끊기는데 키보드의 위쪽 모서리가 둥글어,
    /// 그 모서리 틈으로 뒤에 깔린 딤뷰가 비쳐 좌우 상단이 회색으로 보입니다.
    /// 키보드 뒤로 흰 배경을 이어 두어 그 틈에 시트 색이 보이도록 합니다.
    /// 시트 바깥으로 나가는 뷰라 터치는 받지 않습니다.
    private let keyboardBackdropView = UIView().then {
        $0.backgroundColor = .white
        $0.isUserInteractionEnabled = false
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
        
        addSubview(keyboardBackdropView)
        addSubview(titleLabel)
        addSubview(closeButton)
        addSubview(textField)
        addSubview(errorLabel)
        addSubview(buttonStackView)
        addSubview(loadingContainerView)

        // 두 버튼은 텍스트 스타일이 같고 배경/테두리만 다릅니다.
        [parseButton, linkOnlyButton].forEach { button in
            button.setTitleColor(.gray_700, for: .normal)
            button.setTitleColor(.gray_300, for: .disabled)
            button.titleLabel?.font = TypoStyle.SuitH3.font
        }

        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        parseButton.addTarget(self, action: #selector(parseButtonTapped), for: .touchUpInside)
        linkOnlyButton.addTarget(self, action: #selector(linkOnlyButtonTapped), for: .touchUpInside)
    }
    
    private func setupConstraints() {

        // 화면 밖으로 넘치는 부분은 보이지 않으므로 넉넉하게 내려 둡니다.
        keyboardBackdropView.snp.makeConstraints { make in
            make.top.equalTo(self.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(ShoppingLinkBottomSheet.keyboardBackdropHeight)
        }

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
            make.height.equalTo(ShoppingLinkBottomSheet.buttonHeight)
        }

        textField.snp.makeConstraints { make in
            make.bottom.equalTo(buttonStackView.snp.top).offset(-80)
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
        // 붙여넣기로 앞뒤 공백이 섞여 들어올 수 있어, 검증과 전달 모두 다듬은 값을 씁니다.
        let text = (textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        // 안내 문구가 함께 붙여넣어질 수 있어 본문에서 링크만 찾아 씁니다.
        guard let link = text.firstShoppingLink() else {
            displayError(ErrorMessage.shoppingLink)
            return nil
        }

        // 화면에 보이는 값과 실제 등록되는 값이 달라지지 않도록 입력 필드도 함께 맞춥니다.
        if textField.text != link {
            textField.text = link
        }
        return link
    }
    
    @objc func dismissKeyboard() {
        self.endEditing(true)
    }
    
    private func updateActionButtonState(isEnabled: Bool) {
        parseButton.isEnabled = isEnabled
        linkOnlyButton.isEnabled = isEnabled

        // 비활성 상태에서는 두 버튼 모두 gray_100 배경에 테두리 없이 노출됩니다.
        // (텍스트 컬러는 .disabled 상태로 미리 지정해 두었습니다)
        parseButton.backgroundColor = isEnabled ? .white_10 : .gray_100
        parseButton.layer.borderWidth = isEnabled ? 1 : 0
        linkOnlyButton.backgroundColor = isEnabled ? .green_500 : .gray_100
    }

    /// 입력 필드 하단에 에러 메시지를 노출합니다.
    func displayError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
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
            make.height.equalToSuperview().multipliedBy(0.4)
        }
        
        titleLabel.text = Title.shoppingLinkBottomSheet
        textField.text = prevLink
        errorLabel.isHidden = true
        // 입력 필드가 비어 있으면 두 버튼 모두 비활성화입니다.
        self.updateActionButtonState(isEnabled: (prevLink?.isEmpty == false))
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
