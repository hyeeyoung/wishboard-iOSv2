//
//  ToolBar.swift
//  WishboardV2
//
//  Created by gomin on 8/12/24.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core

public protocol ToolBarDelegate: AnyObject {
    func leftNaviItemTap()
    func itemSelectNaviItemTap()
}

public extension ToolBarDelegate {
    /// 우측 아이템 다중 선택 버튼을 사용하는 화면에서만 구현합니다.
    func itemSelectNaviItemTap() {}
}

final public class ToolBar: UIView {
    
    weak public var delegate: ToolBarDelegate?
    
    // MARK: - Views
    private let backButton = UIButton().then {
        $0.setImage(Image.goBack, for: .normal)
    }
    
    private let titleLabel = UILabel().then {
        $0.font = TypoStyle.SuitH3.font
        $0.textColor = .gray_700
        $0.textAlignment = .center
    }
    
    /// 아이템 다중 선택 진입 버튼 (사용하는 화면에서만 노출)
    private let itemSelectButton = UIButton().then {
        $0.setImage(Image.tabBarCheck, for: .normal)
        $0.isHidden = true
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
        addSubview(itemSelectButton)
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
        
        itemSelectButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-13)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
    }
    
    // MARK: - Setup Actions
    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        itemSelectButton.addTarget(self, action: #selector(itemSelectButtonTapped), for: .touchUpInside)
    }

    // MARK: - Button Actions
    @objc private func backButtonTapped() {
        delegate?.leftNaviItemTap()
    }
    
    @objc private func itemSelectButtonTapped() {
        delegate?.itemSelectNaviItemTap()
    }
    
    public func configure(title: String, showsItemSelectButton: Bool = false) {
        self.titleLabel.text = title
        self.itemSelectButton.isHidden = !showsItemSelectButton
        
        self.snp.makeConstraints { make in
            make.height.equalTo(42)
            make.top.leading.trailing.equalToSuperview()
        }
    }
}
