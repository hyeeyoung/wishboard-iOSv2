//
//  AddToolBar.swift
//  WishboardV2
//
//  Created by gomin on 2/22/25.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core

public protocol AddToolBarDelegate: AnyObject {
    func leftItemTap()
    func rightItemTap()
}

final public class AddToolBar: UIView {
    
    weak public var delegate: AddToolBarDelegate?
    
    // MARK: - Views
    /// 좌측 버튼. 기본은 닫기(X)이고, 화면에 따라 뒤로가기로 바꿀 수 있습니다.
    private let leftButton = UIButton().then {
        $0.setImage(Image.quit, for: .normal)
    }
    
    private let titleLabel = UILabel().then {
        $0.font = TypoStyle.SuitH3.font
        $0.textColor = .gray_700
        $0.textAlignment = .center
    }
    
    /// 글자 기준 상하 7 / 좌우 16의 여백을 가지는 pill 형태
    private static let saveButtonVerticalPadding: CGFloat = 7
    private static let saveButtonHorizontalPadding: CGFloat = 16

    private let saveButton = UIButton().then {
        $0.setTitle("저장", for: .normal)
        $0.titleLabel?.font = TypoStyle.SuitB3.font
        $0.setTitleColor(.gray_300, for: .disabled)
        $0.setTitleColor(.gray_700, for: .normal)
        $0.contentEdgeInsets = UIEdgeInsets(top: AddToolBar.saveButtonVerticalPadding,
                                            left: AddToolBar.saveButtonHorizontalPadding,
                                            bottom: AddToolBar.saveButtonVerticalPadding,
                                            right: AddToolBar.saveButtonHorizontalPadding)
        $0.clipsToBounds = true
    }
    
    // MARK: - Initializer
    public init() {
        super.init(frame: .zero)
        self.backgroundColor = .white
        
        setupViews()
        setupConstraints()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupViews() {
        addSubview(leftButton)
        addSubview(titleLabel)
        addSubview(saveButton)
    }
    
    private func setupConstraints() {
        leftButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(13)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        // 너비는 글자 + 좌우 여백으로 정해지고, 높이는 글자 + 상하 여백으로 정해집니다.
        saveButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }
    
    // MARK: - Setup Actions
    private func setupActions() {
        leftButton.addTarget(self, action: #selector(leftButtonTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        // 글자 크기에 따라 높이가 달라져도 pill 형태를 유지합니다.
        saveButton.layer.cornerRadius = saveButton.bounds.height / 2
    }

    public func updateButtonState(enabled: Bool) {
        if enabled {
            saveButton.backgroundColor = .green_500
            saveButton.isEnabled = true
        } else {
            saveButton.backgroundColor = .gray_100
            saveButton.isEnabled = false
        }
    }

    // MARK: - Button Actions
    @objc private func leftButtonTapped() {
        delegate?.leftItemTap()
    }
    
    @objc private func saveButtonTapped() {
        delegate?.rightItemTap()
    }
    
    /// - Parameter usesBackIcon: 좌측 버튼을 뒤로가기 아이콘으로 바꿀지 여부. 기본은 닫기(X)입니다.
    public func configure(title: String, usesBackIcon: Bool = false) {
        self.titleLabel.text = title
        self.leftButton.setImage(usesBackIcon ? Image.goBack : Image.quit, for: .normal)
        
        self.snp.makeConstraints { make in
            make.height.equalTo(42)
            make.top.leading.trailing.equalToSuperview()
        }
    }
}
