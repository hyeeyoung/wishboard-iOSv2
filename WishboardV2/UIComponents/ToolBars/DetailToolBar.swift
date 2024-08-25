//
//  DetailToolBar.swift
//  WishboardV2
//
//  Created by gomin on 8/18/24.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core

public protocol DetailToolBarDelegate: AnyObject {
    func leftNaviItemTap()
    func deleteNaviItemTap()
    func modifyNaviItemTap()
}

final public class DetailToolBar: UIView {
    
    weak public var delegate: DetailToolBarDelegate?
    
    // MARK: - Views
    private let backBtn = UIButton().then {
        $0.setImage(Image.goBack, for: .normal)
    }
    
    private let deleteBtn = UIButton().then {
        $0.setImage(Image.trash, for: .normal)
    }
    
    private let modifyBtn = UIButton().then {
        $0.setImage(Image.pencil, for: .normal)
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
        addSubview(backBtn)
        addSubview(modifyBtn)
        addSubview(deleteBtn)
    }
    
    private func setupConstraints() {
        backBtn.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        modifyBtn.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        
        deleteBtn.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.trailing.equalTo(modifyBtn.snp.leading).offset(-16)
            make.centerY.equalToSuperview()
        }
    }
    
    // MARK: - Setup Actions
    private func setupActions() {
        backBtn.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        deleteBtn.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        modifyBtn.addTarget(self, action: #selector(modifyButtonTapped), for: .touchUpInside)
    }

    // MARK: - Button Actions
    @objc private func backButtonTapped() {
        delegate?.leftNaviItemTap()
    }
    
    @objc private func deleteButtonTapped() {
        delegate?.deleteNaviItemTap()
    }
    
    @objc private func modifyButtonTapped() {
        delegate?.modifyNaviItemTap()
    }
    
    public func configure() {
        self.snp.makeConstraints { make in
            make.height.equalTo(46)
            make.top.leading.trailing.equalToSuperview()
        }
    }
}
