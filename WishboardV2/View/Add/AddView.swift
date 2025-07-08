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
    
    // Image Pick View
    let imagePickerContainer = UIView().then {
        $0.backgroundColor = .gray_50
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
    }
    
    let cameraContainer = UIView()
    let cameraIcon = UIImageView().then {
        $0.tintColor = .gray_200
        $0.image = Image.cameraGray
    }
    
    let imageCountLabel = UILabel().then {
        $0.text = "0/10"
        $0.font = TypoStyle.SuitD3.font
        $0.textColor = .gray_200
    }
    
    // Contents
    
    let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 0
        $0.alignment = .fill
        $0.distribution = .fill
    }
    
    let itemNameSection = FormItemView(title: Title.itemName,
                                       isRequired: true,
                                       type: .textField(placeholder: Placeholder.uploadItemName,
                                                        isEditable: true,
                                                        showsArrow: false))
    
    let itemPriceSection = FormItemView(title: Title.price,
                                       isRequired: true,
                                       type: .textField(placeholder: Placeholder.uploadItemPrice,
                                                        isEditable: true,
                                                        showsArrow: false))
    
    let folderSection = FormItemView(title: Title.folder,
                                       isRequired: false,
                                       type: .textField(placeholder: Placeholder.uploadItemPrice,
                                                        isEditable: false,
                                                        showsArrow: false))
    
    let alarmSection = FormItemView(title: Title.notificationItem,
                                    isRequired: false,
                                    type: .textField(placeholder: Placeholder.uploadItemNoti,
                                                     isEditable: false,
                                                     showsArrow: true))
     
    let itemLinkSection = FormItemView(title: Title.shoppingMallLink,
                                       isRequired: false,
                                       type: .textField(placeholder: Placeholder.uploadItemLink,
                                                        isEditable: false,
                                                        showsArrow: true))
    
    
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
        $0.text = Placeholder.uploadItemMemo
        $0.textColor = .gray_200
        $0.font = TypoStyle.SuitB3.font
    }
    
    let separatorViews: [UIView] = Array(repeating: UIView().then {
        $0.backgroundColor = .gray_100
    }, count: 6)
    
    // MARK: - Init
    
    public weak var delegate: ActiveFieldDelegate?
    
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
        contentView.addSubview(imagePickerContainer)
        imagePickerContainer.addSubview(cameraContainer)
        cameraContainer.addSubview(cameraIcon)
        cameraContainer.addSubview(imageCountLabel)
        contentView.addSubview(stackView)
        memoTextView.addSubview(memoPlaceholder)
        
        toolBar.configure(title: Title.addItem)
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(toolBar.snp.bottom)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(super.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        imagePickerContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.leading.equalToSuperview().offset(16)
            make.width.height.equalTo(100)
        }
        
        cameraContainer.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        cameraIcon.snp.makeConstraints { make in
            make.width.height.equalTo(26)
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        
        imageCountLabel.snp.makeConstraints { make in
            make.top.equalTo(cameraIcon.snp.bottom).offset(6)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        stackView.snp.makeConstraints { make in
            make.top.equalTo(imagePickerContainer.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-16)
        }
        
        memoPlaceholder.snp.makeConstraints { make in
            make.leading.trailing.equalTo(memoTextView).inset(16)
            make.top.equalTo(memoTextView).offset(16)
        }

        let fields: [UIView] = [
            itemNameSection, itemPriceSection, folderSection, alarmSection, itemLinkSection, memoTextView
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
                    make.height.equalTo(84)
                }
            }
            
            if index < fields.count - 1 { // 마지막 항목에는 구분선 안 붙이기
                stackView.addArrangedSubview(separatorView)
                separatorView.snp.makeConstraints { make in
                    make.height.equalTo(0.5)
                }
            }
        }
    }
    
    private func setupDelegates() {
        itemPriceSection.onTextChanged = { [weak self] textField in
            self?.delegate?.setActiveField(textField)
            self?.priceTextChanged(textField)
        }
        itemNameSection.onTextChanged = { [weak self] textField in
            self?.delegate?.setActiveField(textField)
        }
    }
    
    private func priceTextChanged(_ textField: UITextField) {
        guard let currentText = textField.text as String? else { return }
        let filteredText = currentText.filter { $0.isNumber }
        if filteredText.isEmpty {
            textField.text = nil
            return
        }
        let formattedText = FormatManager.shared.strToPrice(numStr: filteredText)
        textField.text = "\(formattedText ?? "")원"
    }
    
    @objc func priceTextBegin(_ textField: UITextField) {
        self.delegate?.setActiveField(textField)
    }
}
