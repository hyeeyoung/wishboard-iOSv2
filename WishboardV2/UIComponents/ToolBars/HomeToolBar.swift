//
//  HomeToolBar.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core

public protocol HomeToolBarDelegate: AnyObject {
    func alarmNaviItemTap()
}

final public class HomeToolBar: UIView {
    
    weak public var delegate: HomeToolBarDelegate?
    
    // MARK: - Views
    private let logo = UIImageView().then {
        $0.image = Image.homeAppLogo
    }
    
    private let alarmButton = UIButton().then {
        $0.tintColor = .gray_700
        $0.setImage(Image.notice, for: .normal)
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
        addSubview(logo)
        addSubview(alarmButton)
    }
    
    private func setupConstraints() {
        logo.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(147.94)
            make.height.equalTo(18)
        }
        
        alarmButton.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }
    
    // MARK: - Setup Actions
    private func setupActions() {
        alarmButton.addTarget(self, action: #selector(alarmButtonTapped), for: .touchUpInside)
    }

    // MARK: - Button Actions
    @objc private func alarmButtonTapped() {
        delegate?.alarmNaviItemTap()
    }
    
    public func configure() {
        self.snp.makeConstraints { make in
            make.height.equalTo(52)
            make.top.leading.trailing.equalToSuperview()
        }
    }
}
