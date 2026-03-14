//
//  BaseToolBar.swift
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
    func reorderFolderNaviItemTap()
    func addFolderNaviItemTap()
}

final public class BaseToolBar: UIView {
    
    weak public var delegate: FolderToolBarDelegate? {
        didSet {
            if let _ = self.delegate {
                plusButton.isHidden = false
                reorderButton.isHidden = false
                setupActions()
            } else {
                plusButton.isHidden = true
                reorderButton.isHidden = true
            }
        }
    }
    
    // MARK: - Views
    private let titleLabel = UILabel().then {
        $0.text = "폴더"
        $0.font = TypoStyle.SuitH1.font
        $0.textColor = .gray_700
    }
    
    private let plusButton = UIButton().then {
        $0.setImage(Image.newFolder, for: .normal)
        $0.isHidden = true
    }
    
    private let reorderButton = UIButton().then {
        $0.setImage(Image.reorderFolder, for: .normal)
        $0.isHidden = true
    }
    
    // MARK: - Initializer
    public init() {
        super.init(frame: .zero)
        self.backgroundColor = .white
        
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupViews() {
        addSubview(titleLabel)
        addSubview(plusButton)
        addSubview(reorderButton)
    }
    
    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        plusButton.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        
        reorderButton.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.trailing.equalTo(plusButton.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }
    }
    
    // MARK: - Setup Actions
    private func setupActions() {
        plusButton.addTarget(self, action: #selector(plusButtonTapped), for: .touchUpInside)
        reorderButton.addTarget(self, action: #selector(reorderButtonTapped), for: .touchUpInside)
    }

    // MARK: - Button Actions
    @objc private func plusButtonTapped() {
        delegate?.addFolderNaviItemTap()
    }
    
    @objc private func reorderButtonTapped() {
        delegate?.reorderFolderNaviItemTap()
    }
    
    public func configure(title: String) {
        titleLabel.text = title
        self.snp.makeConstraints { make in
            make.height.equalTo(50)
            make.top.leading.trailing.equalToSuperview()
        }
    }
}
