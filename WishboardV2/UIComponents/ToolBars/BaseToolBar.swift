//
//  FolderToolBar.swift
//  WishboardV2
//
//  Created by gomin on 8/18/24.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core

public protocol FolderToolBarDelegate: AnyObject {
    func rightNaviItemTap()
}

final public class BaseToolBar: UIView {
    
    weak public var delegate: FolderToolBarDelegate?
    
    // MARK: - Views
    private let title = UILabel().then {
        $0.text = "폴더"
        $0.font = TypoStyle.SuitH1.font
        $0.textColor = .gray_700
    }
    
    private let plusButton = UIButton().then {
        $0.setImage(Image.newFolder, for: .normal)
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
        addSubview(title)
        addSubview(plusButton)
    }
    
    private func setupConstraints() {
        title.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        plusButton.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }
    
    // MARK: - Setup Actions
    private func setupActions() {
        plusButton.addTarget(self, action: #selector(plusButtonTapped), for: .touchUpInside)
    }

    // MARK: - Button Actions
    @objc private func plusButtonTapped() {
        delegate?.rightNaviItemTap()
    }
    
    public func configure() {
        self.snp.makeConstraints { make in
            make.height.equalTo(50)
            make.top.leading.trailing.equalToSuperview()
        }
    }
}
