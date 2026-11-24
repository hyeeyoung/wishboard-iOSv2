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
import WBNetwork

final class HomeEventBannerView: UIView {

    var onClose: (() -> Void)?
    var onTap: (() -> Void)?

    // MARK: - Views

    private let eventLabel = UILabel().then {
        $0.font = TypoStyle.SuitD2.font
        $0.textAlignment = .left
    }

    private let closeButton = UIButton().then {
        $0.setImage(Image.whiteQuit.withRenderingMode(.alwaysTemplate), for: .normal)
    }

    /// 닫기 버튼이 없을 때 자리를 없애, 문구가 더 길게 들어가도록 합니다.
    private var closeButtonWidth: Constraint?

    // MARK: - Configure

    /// 서버가 내려준 배너 한 건을 반영합니다.
    func configure(with banner: BannerEvent) {
        eventLabel.text = banner.text

        // 색상 문자열이 깨져 있어도 배너가 사라지지 않도록 기존 색으로 넘어갑니다.
        let textColor = UIColor(argbHexString: banner.textColor) ?? .white_10
        eventLabel.textColor = textColor
        // 닫기 아이콘은 문구 색을 따라가되 조금 옅게 둡니다.
        closeButton.tintColor = textColor.withAlphaComponent(0.6)
        backgroundColor = UIColor(argbHexString: banner.backgroundColor) ?? .black

        closeButton.isHidden = !banner.isDismissible
        closeButtonWidth?.update(offset: banner.isDismissible ? 16 : 0)

        // 반응이 없는 배너는 눌리지 않게 둡니다.
        isUserInteractionEnabled = banner.action != .none
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
            make.trailing.equalToSuperview().offset(-13)
            make.centerY.equalToSuperview()
            make.height.equalTo(16)
            self.closeButtonWidth = make.width.equalTo(16).constraint
        }

        eventLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalTo(closeButton.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }
    }

    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(bannerTapped(_:)))
        addGestureRecognizer(tapGesture)
    }

    @objc private func closeTapped() {
        onClose?()
    }

    @objc private func bannerTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        guard !closeButton.frame.contains(location) else { return }
        onTap?()
    }
}
