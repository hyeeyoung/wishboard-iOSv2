//
//  ItemSelectionToolBar.swift
//  WishboardV2
//
//  Created by gomin on 2026/09/18.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core

public protocol ItemSelectionToolBarDelegate: AnyObject {
    /// 다중 선택 모드 종료 (x 버튼)
    func selectionCloseButtonTap()
}

/// 아이템 다중 선택 모드에서 기존 툴바/스티키헤더 대신 노출되는 상단바
final public class ItemSelectionToolBar: UIView {

    public static let height: CGFloat = 42

    weak public var delegate: ItemSelectionToolBarDelegate?

    // MARK: - Views
    private let closeButton = UIButton().then {
        $0.setImage(Image.quit, for: .normal)
        $0.tintColor = .gray_700
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
        addSubview(closeButton)
    }

    private func setupConstraints() {
        closeButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(13)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
    }

    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }

    // MARK: - Button Actions
    @objc private func closeButtonTapped() {
        UIDevice.vibrate()
        delegate?.selectionCloseButtonTap()
    }
}
