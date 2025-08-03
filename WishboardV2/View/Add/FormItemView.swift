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
            textView?.text = newValue
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
            make.leading.equalToSuperview()
            make.top.equalToSuperview()
        }
        
        requiredStar.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(4)
            make.centerY.equalTo(titleLabel)
        }

        mainContainer.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(16)
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
                make.leading.trailing.bottom.equalToSuperview()
                make.top.equalTo(titleLabel.snp.bottom).offset(14)
            }

        case .textView:
            let tv = UITextView().then {
                $0.font = TypoStyle.SuitD1.font
                $0.textColor = .gray_700
                $0.isScrollEnabled = false
                $0.textContainerInset = .zero
                $0.textContainer.lineFragmentPadding = 0
            }
            self.textView = tv
            mainContainer.addSubview(tv)
            tv.snp.makeConstraints { make in
                make.height.greaterThanOrEqualTo(120)
                make.leading.bottom.equalToSuperview()
                make.top.equalTo(titleLabel.snp.bottom).offset(14)
            }

            // placeholder label
            let placeholder = UILabel().then {
                $0.text = Placeholder.uploadItemMemo
                $0.textColor = .gray_200
                $0.font = TypoStyle.SuitD1.font
                $0.numberOfLines = 0
                $0.lineBreakMode = .byCharWrapping
            }
            placeholderLabel = placeholder
            mainContainer.addSubview(placeholder)
            placeholder.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(titleLabel.snp.bottom).offset(14)
            }

            // textView text change 감지
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(textViewDidChange),
                name: UITextView.textDidChangeNotification,
                object: tv
            )
        case .folder:
            // TODO: 상속 받아서 구현 or delegate 활용해 외부 구성
            break
        }
    }
    
    // MARK: - 액션 메서드
    @objc
    private func textDidChange(_ sender: UITextField) {
        onTextChanged?(sender)
        textSubject.send(sender.text ?? "")
    }
    
    @objc private func handleTap() {
        self.onTap?()
    }
    
    @objc private func textViewDidChange(_ notification: Foundation.Notification) {
        guard let textView = self.textView else { return }
        placeholderLabel?.isHidden = !textView.text.isEmpty
        textSubject.send(textView.text ?? "")
    }
}
