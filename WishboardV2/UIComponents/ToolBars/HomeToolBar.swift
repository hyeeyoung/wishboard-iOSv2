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
    func cartNaviItemTap()
    func calendarNaviItemTap()
}

final public class HomeToolBar: UIView {
    
    weak public var delegate: HomeToolBarDelegate?
    
    // MARK: - Views
    private let logo = UIImageView().then {
        $0.image = Image.homeAppLogo
    }
    
    private let cartButton = UIButton().then {
        $0.setImage(Image.cartIcon, for: .normal)
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
        addSubview(logo)
        addSubview(cartButton)
        addSubview(calendarButton)
    }
    
    private func setupConstraints() {
        logo.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(147.94)
            make.height.equalTo(18)
        }
        
        calendarButton.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        
        cartButton.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.trailing.equalTo(calendarButton.snp.leading).offset(-16)
            make.centerY.equalToSuperview()
        }
    }
    
    // MARK: - Setup Actions
    private func setupActions() {
        cartButton.addTarget(self, action: #selector(cartButtonTapped), for: .touchUpInside)
        calendarButton.addTarget(self, action: #selector(calendarButtonTapped), for: .touchUpInside)
    }

    // MARK: - Button Actions
    @objc private func cartButtonTapped() {
        delegate?.cartNaviItemTap()
    }
    
    @objc private func calendarButtonTapped() {
        delegate?.calendarNaviItemTap()
    }
    
    public func configure() {
        self.snp.makeConstraints { make in
            make.height.equalTo(52)
            make.top.leading.trailing.equalToSuperview()
        }
    }
}
