//
//  HomeEventBannerView.swift
//  WishboardV2
//
//  Created by gomin on 2026/08/30.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core

final class HomeEventBannerView: UIView {

    var onClose: (() -> Void)?

    // MARK: - Views

    private let eventLabel = UILabel().then {
        $0.text = "지금 위시보드 이벤트 진행 중 🎉"
        $0.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        $0.textColor = .white
        $0.textAlignment = .center
    }

    private let closeButton = UIButton(type: .system).then {
        $0.setImage(Image.whiteQuit.withRenderingMode(.alwaysOriginal), for: .normal)
    }

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        setupViews()
        setupConstraints()
        setupActions()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupViews() {
        addSubview(eventLabel)
        addSubview(closeButton)
    }

    private func setupConstraints() {
        closeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }

        eventLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalTo(closeButton.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }
    }

    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }

    @objc private func closeTapped() {
        onClose?()
    }
}
