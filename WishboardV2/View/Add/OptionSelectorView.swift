//
//  OptionSelectorView.swift
//  WishboardV2
//
//  Created by gomin on 2/22/25.
//

import Foundation
import UIKit
import Then
import SnapKit
import Core

final class OptionSelectorView: UIView {
    
    // MARK: - Properties
    private let label = UILabel().then {
        $0.font = TypoStyle.SuitB3.font
        $0.textColor = .black
    }
    
    private let arrowButton = UIButton().then {
        $0.setImage(Image.arrowRight, for: .normal)
        $0.tintColor = .gray
    }
    
    var onTap: (() -> Void)? // 탭제스처 콜백

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        self.backgroundColor = .white
        self.addSubview(label)
        self.addSubview(arrowButton)
        
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        arrowButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }
    
    private func setupGesture() {
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }
    
    @objc private func handleTap() {
        onTap?()
    }
    
    // MARK: - Update
    func configure(_ title: String) {
        label.text = title
    }
    
    func updateText(_ text: String) {
        label.text = text
    }
}
