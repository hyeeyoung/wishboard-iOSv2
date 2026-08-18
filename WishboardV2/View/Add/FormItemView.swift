//
//  FormItemView.swift
//  WishboardV2
//
//  Created by gomin on 7/8/25.
//

import Foundation
import UIKit
import SnapKit
import Combine
import Then
import Core

enum FormItemType {
    case textField(
        placeholder: String,
        isEditable: Bool,
        showsArrow: Bool,
        showsNumberPad: Bool
    )
    case textView
    case folder  // 별도로 상속해서 처리 가능
}

class FormItemView: UIView {
    
    private let textSubject = CurrentValueSubject<String, Never>("")

    /// 현재 텍스트를 외부에서 set/get 할 수 있게
    public var text: String {
        get {
            textField?.text ?? textView?.text ?? ""
        }
        set {
            textField?.text = newValue

            if let tv = textView {
                // Placeholder는 실제 text에 넣지 않는다.
                // UITextView에는 실제 입력값만 유지한다.
                tv.text = newValue
                tv.textColor = .gray_700

                updateTextViewPlaceholder()
            }

            textSubject.send(newValue)
        }
    }

    /// Combine 퍼블리셔
    public var textPublisher: AnyPublisher<String, Never> {
        textSubject.eraseToAnyPublisher()
    }

    public var onTextChanged: ((UITextField) -> Void)?
    public var onTap: (() -> Void)?

    // MARK: - UI Components
    
    let mainContainer = UIView()
    
    public let titleLabel = UILabel().then {
        $0.font = TypoStyle.SuitB2.font
        $0.textColor = .gray_700
    }

    private let requiredStar = UILabel().then {
        $0.font = TypoStyle.SuitB2.font
        $0.text = "*"
        $0.textColor = .green_700
    }

    public private(set) var textView: UITextView?
    public private(set) var textField: UITextField?

    /// TextView 전용 placeholder
    private var placeholderLabel: UILabel?
    
    private var arrowImageView: UIImageView?

    // MARK: - Init

    init(title: String, isRequired: Bool, type: FormItemType) {
        super.init(frame: .zero)
        
        addSubViews()
        setupUI(
            title: title,
            isRequired: isRequired,
            type: type
        )
        
        let gesture = UITapGestureRecognizer(
            target: self,
            action: #selector(handleTap)
        )
        gesture.cancelsTouchesInView = false
        self.addGestureRecognizer(gesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - UI Setup

    private func addSubViews() {
        self.addSubview(mainContainer)

        mainContainer.addSubview(titleLabel)
        mainContainer.addSubview(requiredStar)
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview()
        }
        
        requiredStar.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(4)
            make.centerY.equalTo(titleLabel)
        }

        mainContainer.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(16)
        }
    }
    
    private func setupUI(
        title: String,
        isRequired: Bool,
        type: FormItemType
    ) {
        // Title
        titleLabel.text = title
        
        // Star
        requiredStar.isHidden = !isRequired
        
        switch type {
        case .textField(
            let placeholder,
            let isEditable,
            let showsArrow,
            let showsNumberPad
        ):
            setUpTextFieldUI(
                placeholder: placeholder,
                isEditable: isEditable,
                showsArrow: showsArrow,
                showsNumberPad: showsNumberPad
            )

        case .textView:
            setUpTextViewUI()

        case .folder:
            // TODO: 상속 받아서 구현 or delegate 활용해 외부 구성
            break
        }
    }

    // MARK: - TextField

    private func setUpTextFieldUI(
        placeholder: String,
        isEditable: Bool,
        showsArrow: Bool,
        showsNumberPad: Bool
    ) {
        let tf = UITextField().then {
            $0.placeholder = placeholder
            $0.borderStyle = .none
            $0.isEnabled = isEditable
            $0.font = TypoStyle.SuitD1.font
            $0.autocapitalizationType = .none
            $0.autocorrectionType = .no
            $0.spellCheckingType = .no
            $0.keyboardType = showsNumberPad ? .numberPad : .default
            $0.addTarget(
                self,
                action: #selector(textDidChange(_:)),
                for: .allEvents
            )
        }

        tf.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: UIColor.gray_200
            ]
        )

        tf.snp.makeConstraints { make in
            make.height.equalTo(22)
        }

        self.textField = tf

        if showsNumberPad {
            self.textField?.delegate = self
        }

        let textFieldContainer = UIStackView(
            arrangedSubviews: [tf]
        ).then {
            $0.axis = .horizontal
            $0.spacing = 8
            $0.alignment = .fill
        }

        if showsArrow {
            let arrow = UIImageView(image: .arrowRight).then {
                $0.contentMode = .scaleAspectFit
            }

            arrowImageView = arrow

            textFieldContainer.addArrangedSubview(arrow)

            arrow.snp.makeConstraints { make in
                make.width.height.equalTo(24)
            }

            self.textField?.snp.updateConstraints { make in
                make.height.equalTo(24)
            }
        }
        
        mainContainer.addSubview(textFieldContainer)

        textFieldContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(14)
        }
    }

    // MARK: - TextView

    private func setUpTextViewUI() {
        let placeholderText = Placeholder.uploadItemMemo

        let tv = UITextView().then {
            $0.font = TypoStyle.SuitD1.font
            $0.textColor = .gray_700

            // 중요:
            // Placeholder를 실제 text에 넣지 않는다.
            $0.text = ""

            $0.isScrollEnabled = false
            $0.textContainerInset = .zero
            $0.textContainer.lineFragmentPadding = 0
            $0.isUserInteractionEnabled = true
            $0.isEditable = true
            $0.autocorrectionType = .no
            $0.autocapitalizationType = .none
        }

        tv.delegate = self
        self.textView = tv

        mainContainer.addSubview(tv)

        tv.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(120)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.lessThanOrEqualToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(14)
        }

        // MARK: Placeholder Label

        let placeholderLabel = UILabel().then {
            $0.text = placeholderText
            $0.font = TypoStyle.SuitD1.font
            $0.textColor = .gray_200
            $0.numberOfLines = 0
            $0.isUserInteractionEnabled = false
        }

        self.placeholderLabel = placeholderLabel

        mainContainer.addSubview(placeholderLabel)

        placeholderLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(tv)
            make.top.equalTo(tv)
        }

        // 초기 상태에서는 placeholder 노출
        updateTextViewPlaceholder()
    }

    // MARK: - TextView Placeholder

    /// UITextView의 실제 text와 placeholder의 표시 상태를 동기화한다.
    ///
    /// 중요한 점:
    /// placeholder는 UITextView.text에 들어가지 않는다.
    /// 실제 사용자 입력이 비어 있을 때만 UILabel을 보여준다.
    private func updateTextViewPlaceholder() {
        guard let textView else {
            return
        }

        let isEmpty = textView.text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty

        placeholderLabel?.isHidden = !isEmpty
    }

    // MARK: - 액션 메서드

    @objc private func textDidChange(_ sender: UITextField) {
        onTextChanged?(sender)
        textSubject.send(sender.text ?? "")
    }

    @objc private func handleTap() {
        self.onTap?()
    }
}

// MARK: - UITextView Delegate

extension FormItemView: UITextViewDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {
        // Placeholder는 별도의 UILabel이므로
        // textView.text를 수정할 필요가 없다.
        updateTextViewPlaceholder()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        updateTextViewPlaceholder()
    }

    func textViewDidChange(_ textView: UITextView) {
        // 실제 입력값만 유지한다.
        // 비어 있으면 placeholder UILabel만 노출한다.
        updateTextViewPlaceholder()

        // Combine에는 실제 입력값만 발행
        textSubject.send(textView.text ?? "")
    }
}

// MARK: - UITextField Delegate

extension FormItemView: UITextFieldDelegate {

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        
        // 백스페이스 허용
        if string.isEmpty {
            return true
        }
        
        // 현재 텍스트
        let currentText = textField.text ?? ""
        
        // 입력 적용 후의 텍스트 시뮬레이션
        if let textRange = Range(range, in: currentText) {
            let updatedText = currentText.replacingCharacters(
                in: textRange,
                with: string
            )
            
            // 숫자만 추출
            let filtered = updatedText.filter { $0.isNumber }
            
            // 최대값 체크
            if let number = Int(filtered),
               number > 999_999_999 {
                return false
            }
        }
        
        return true
    }
}
