//
//  EmailInputToolBar.swift
//  WishboardV2
//
//  Created by gomin on 3/4/25.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core

public protocol EmailInputToolBarDelegate: AnyObject {
    func leftNaviItemTap()
}

final public class EmailInputToolBar: UIView {
    
    weak public var delegate: EmailInputToolBarDelegate?
    
    // MARK: - Views
    private let backButton = UIButton().then {
        $0.setImage(Image.goBack, for: .normal)
    }
    
    private let titleLabel = UILabel().then {
        $0.font = TypoStyle.SuitH3.font
        $0.textColor = .gray_700
        $0.textAlignment = .center
    }
    
    private let rightButton = UIButton().then {
        $0.setTitle("1/2단계", for: .normal)
        $0.titleLabel?.font = TypoStyle.SuitD2.font
        $0.setTitleColor(.gray_700, for: .normal)
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
        addSubview(backButton)
        addSubview(titleLabel)
        addSubview(rightButton)
    }
    
    private func setupConstraints() {
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(13)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        rightButton.snp.makeConstraints { make in
//            make.width.height.equalTo(24)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }
    
    // MARK: - Setup Actions
    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }

    // MARK: - Button Actions
    @objc private func backButtonTapped() {
        delegate?.leftNaviItemTap()
    }
    
    public func configure(title: String) {
        self.titleLabel.text = title
        
//        self.snp.makeConstraints { make in
//            make.height.equalTo(42)
//            make.leading.trailing.equalToSuperview()
//            make.top.equalTo(super.safeAreaLayoutGuide.snp.top).offset(16)
//        }
    }
}
