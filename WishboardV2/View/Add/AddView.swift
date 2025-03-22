//
//  AddView.swift
//  WishboardV2
//
//  Created by gomin on 2/22/25.
//

import Foundation
import UIKit
import SnapKit
import Combine
import Then
import Core

final class AddView: UIView {
    
    // MARK: - UI Components
    
    let toolBar = AddToolBar()
    
    let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.keyboardDismissMode = .onDrag
    }
    
    let contentView = UIView()
    
    let imagePickerView = UIImageView().then {
        $0.backgroundColor = .gray_100
        $0.layer.cornerRadius = 32
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
    }
    
    let cameraIcon = UIImageView().then {
        $0.tintColor = .gray_200
        $0.image = Image.cameraGray
    }
    
    let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 0
        $0.alignment = .fill
        $0.distribution = .fill
    }
    
    let itemNameTextField = UITextField().then {
        $0.placeholder = "상품명(필수)"
        $0.font = TypoStyle.SuitB3.font
        $0.borderStyle = .none
        $0.setLeftPaddingPoints(16)
        $0.autocapitalizationType = .none
        $0.autocorrectionType = .no
    }
    
    let itemPriceTextField = UITextField().then {
        $0.placeholder = "₩ 가격(필수)"
        $0.font = TypoStyle.SuitB3.font
        $0.keyboardType = .numberPad
        $0.borderStyle = .none
        $0.setLeftPaddingPoints(16)
    }
    
    let folderView = OptionSelectorView().then {
        $0.configure("폴더")
    }
    let alarmView = OptionSelectorView().then {
        $0.configure("상품 일정 알림")
    }
    let linkView = OptionSelectorView().then {
        $0.configure("쇼핑몰 링크")
    }
    
    let memoTextView = UITextView().then {
        $0.font = TypoStyle.SuitB3.font
        $0.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        $0.textContainer.lineFragmentPadding = 0
        $0.autocorrectionType = .no
        $0.autocapitalizationType = .none
        $0.isSelectable = true
        $0.dataDetectorTypes = [.all]
    }
    
    let memoPlaceholder = UILabel().then {
        $0.text = "브랜드, 사이즈, 컬러 등 아이템 정보를 적어보세요! 😉"
        $0.textColor = .gray_200
        $0.font = TypoStyle.SuitB3.font
    }
    
    let separatorViews: [UIView] = Array(repeating: UIView().then {
        $0.backgroundColor = .lightGray
    }, count: 6)
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
        setupDelegates()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        addSubview(toolBar)
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(imagePickerView)
        imagePickerView.addSubview(cameraIcon)
        contentView.addSubview(stackView)
        memoTextView.addSubview(memoPlaceholder)
        
        toolBar.configure(title: "아이템 추가")
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(toolBar.snp.bottom)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(super.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        imagePickerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(imagePickerView.snp.width).multipliedBy(0.67)
        }
        
        cameraIcon.snp.makeConstraints { make in
            make.width.equalTo(32.81)
            make.height.equalTo(29.17)
            make.center.equalTo(imagePickerView)
        }
        
        stackView.snp.makeConstraints { make in
            make.top.equalTo(imagePickerView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-16)
        }
        
        memoPlaceholder.snp.makeConstraints { make in
            make.leading.trailing.equalTo(memoTextView).inset(16)
            make.top.equalTo(memoTextView).offset(16)
        }

        let fields: [UIView] = [
            itemNameTextField, itemPriceTextField, folderView, alarmView, linkView, memoTextView
        ]
        
        for (index, field) in fields.enumerated() {
            let separatorView = UIView().then { $0.backgroundColor = .gray_100 }
            
            stackView.addArrangedSubview(field)
            
            if field == memoTextView {
                field.snp.makeConstraints { make in
                    make.height.equalTo(300)
                }
            } else {
                field.snp.makeConstraints { make in
                    make.height.equalTo(55)
                }
            }
            
            if index < fields.count - 1 { // 마지막 항목에는 구분선 안 붙이기
                stackView.addArrangedSubview(separatorView)
                separatorView.snp.makeConstraints { make in
                    make.height.equalTo(1)
                }
            }
        }
    }
    
    private func setupDelegates() {
        self.itemPriceTextField.addTarget(self, action: #selector(priceTextChanged(_:)), for: .editingChanged)
    }
    
    @objc func priceTextChanged(_ textField: UITextField) {
        guard let currentText = textField.text as String? else { return }
        let filteredText = currentText.filter { $0.isNumber }
        let formattedText = FormatManager.shared.strToPrice(numStr: filteredText)
        textField.text = formattedText
    }
}
