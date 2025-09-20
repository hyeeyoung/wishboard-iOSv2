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
    case textField(placeholder: String, isEditable: Bool, showsArrow: Bool, showsNumberPad: Bool)
    case textView
    case folder  // 별도로 상속해서 처리 가능
}

class FormItemView: UIView {
    
    private let textSubject = CurrentValueSubject<String, Never>("")

    /// 현재 텍스트를 외부에서 set/get 할 수 있게
    public var text: String {
        get { textField?.text ?? textView?.text ?? "" }
        set {
            textField?.text = newValue
            if let tv = textView {
                if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    tv.text = Placeholder.uploadItemMemo
                    tv.textColor = .gray_200
                } else {
                    tv.text = newValue
                    tv.textColor = .gray_700
                }
            }
            textSubject.send(newValue)      // 초기값 세팅 시에도 발행
            placeholderLabel?.isHidden = !(newValue.isEmpty)
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
    private var placeholderLabel: UILabel?
    private var arrowImageView: UIImageView?

    // MARK: - Init
    init(title: String, isRequired: Bool, type: FormItemType) {
        super.init(frame: .zero)
        
        addSubViews()
        setupUI(title: title, isRequired: isRequired, type: type)
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
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
    
    private func setupUI(title: String, isRequired: Bool, type: FormItemType) {
        // Title
        titleLabel.text = title
        
        // Star
        requiredStar.isHidden = !isRequired
        
        switch type {
        case .textField(let placeholder, let isEditable, let showsArrow, let showsNumberPad):
            self.setUpTextFieldUI(placeholder: placeholder, isEditable: isEditable, showsArrow: showsArrow, showsNumberPad: showsNumberPad)

        case .textView:
            let placeholderText = Placeholder.uploadItemMemo

            let tv = UITextView().then {
                $0.font = TypoStyle.SuitD1.font
                $0.textColor = .gray_200  // 초기 색상: 플레이스홀더 색
                $0.text = placeholderText // 초기 텍스트: 플레이스홀더
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
        case .folder:
            // TODO: 상속 받아서 구현 or delegate 활용해 외부 구성
            break
        }
    }
    
    private func setUpTextFieldUI(placeholder: String, isEditable: Bool, showsArrow: Bool, showsNumberPad: Bool) {
        let tf = UITextField().then {
            $0.placeholder = placeholder
            $0.borderStyle = .none
            $0.isEnabled = isEditable
            $0.font = TypoStyle.SuitD1.font
            $0.autocapitalizationType = .none
            $0.autocorrectionType = .no
            $0.spellCheckingType = .no
            $0.keyboardType = showsNumberPad ? .numberPad : .default
            $0.addTarget(self, action: #selector(textDidChange(_:)), for: .allEvents)
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

        let textFieldContainer = UIStackView(arrangedSubviews: [tf]).then {
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
            self.textField?.snp.updateConstraints({ make in
                make.height.equalTo(24)
            })
        }
        
        mainContainer.addSubview(textFieldContainer)
        textFieldContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(14)
        }
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
        if textView.text == Placeholder.uploadItemMemo {
            textView.text = ""
            textView.textColor = .gray_700 // 실제 입력 텍스트 색상
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = Placeholder.uploadItemMemo
            textView.textColor = .gray_200
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        if textView.text == Placeholder.uploadItemMemo {
            textView.textColor = .gray_200
        } else {
            textView.textColor = .gray_700 // 실제 입력 텍스트 색상
        }
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = Placeholder.uploadItemMemo
            textView.textColor = .gray_200
        }
        textSubject.send(textView.text ?? "")
    }
}

extension FormItemView: UITextFieldDelegate {
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        
        // 백스페이스 허용
        if string.isEmpty {
            return true
        }
        
        // 현재 텍스트
        let currentText = textField.text ?? ""
        
        // 입력 적용 후의 텍스트 시뮬레이션
        if let textRange = Range(range, in: currentText) {
            let updatedText = currentText.replacingCharacters(in: textRange, with: string)
            
            // 숫자만 추출
            let filtered = updatedText.filter { $0.isNumber }
            
            // 최대값 체크
            if let number = Int(filtered), number > 999_999_999 {
                return false // → 입력 차단
            }
        }
        
        return true
    }
}
