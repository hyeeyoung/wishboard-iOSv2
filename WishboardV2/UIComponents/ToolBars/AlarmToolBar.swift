//
//  AlarmToolBar.swift
//  WishboardV2
//
//  Created by gomin on 2/21/25.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core

public protocol AlarmToolBarDelegate: AnyObject {
    func leftNaviItemTap()
    func calendarNaviItemTap()
}

final public class AlarmToolBar: UIView {
    
    weak public var delegate: AlarmToolBarDelegate?
    
    // MARK: - Views
    private let backButton = UIButton().then {
        $0.setImage(Image.goBack, for: .normal)
    }
    
    private let titleLabel = UILabel().then {
        $0.font = TypoStyle.SuitH3.font
        $0.textColor = .gray_700
        $0.textAlignment = .center
    }
    
    private let calendarButton = UIButton().then {
        $0.setImage(Image.calender, for: .normal)
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
        addSubview(calendarButton)
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
        
        calendarButton.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }
    
    // MARK: - Setup Actions
    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        calendarButton.addTarget(self, action: #selector(calendarButtonTapped), for: .touchUpInside)
    }

    // MARK: - Button Actions
    @objc private func backButtonTapped() {
        delegate?.leftNaviItemTap()
    }
    
    @objc private func calendarButtonTapped() {
        delegate?.calendarNaviItemTap()
    }
    
    public func configure(title: String) {
        self.titleLabel.text = title
        
        self.snp.makeConstraints { make in
            make.height.equalTo(42)
            make.top.leading.trailing.equalToSuperview()
        }
    }
}
