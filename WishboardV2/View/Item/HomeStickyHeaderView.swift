//
//  HomeStickyHeaderView.swift
//  WishboardV2
//
//  Created by gomin on 2026/08/26.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core

protocol HomeStickyHeaderDelegate: AnyObject {
    func didToggleExcludeOwned()
    func didChangeGridColumn(_ column: GridColumnType)
}

final class HomeStickyHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "HomeStickyHeaderView"

    weak var delegate: HomeStickyHeaderDelegate?

    // MARK: - Views

    private let totalCountLabel = UILabel().then {
        $0.setTypoStyleWithSingleLine(typoStyle: .SuitD3)
        $0.textColor = .gray_200
    }

    private let checkboxButton = UIButton(type: .custom).then {
        $0.setImage(.ownedCircle, for: .normal)
        $0.setImage(.ownedCircleCheck, for: .selected)
        $0.isHidden = true
    }

    private let excludeOwnedLabel = UILabel().then {
        $0.text = "소장템 제외"
        $0.setTypoStyleWithSingleLine(typoStyle: .SuitD3)
        $0.textColor = .gray_200
        $0.isHidden = true
    }

    private let gridButton = UIButton(type: .custom).then {
        $0.tintColor = .gray_300
    }

    // MARK: - Properties

    private(set) var currentColumn: GridColumnType = {
        GridColumnType(rawValue: UserManager.gridColumnType) ?? .two
    }()

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupViews()
        setupConstraints()
        setupActions()
        updateGridButtonIcon()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        addSubview(totalCountLabel)
        addSubview(checkboxButton)
        addSubview(excludeOwnedLabel)
        addSubview(gridButton)
    }

    private func setupConstraints() {
        totalCountLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        gridButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }

        excludeOwnedLabel.snp.makeConstraints { make in
            make.trailing.equalTo(gridButton.snp.leading).offset(-10)
            make.centerY.equalToSuperview()
        }

        checkboxButton.snp.makeConstraints { make in
            make.trailing.equalTo(excludeOwnedLabel.snp.leading).offset(-5)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(14)
        }
    }

    private func setupActions() {
        checkboxButton.addTarget(self, action: #selector(toggleExcludeOwned), for: .touchUpInside)
        gridButton.addTarget(self, action: #selector(gridButtonTapped), for: .touchUpInside)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleExcludeOwned))
        excludeOwnedLabel.isUserInteractionEnabled = true
        excludeOwnedLabel.addGestureRecognizer(tapGesture)
    }

    private func updateGridButtonIcon() {
        var gridIconImage: UIImage = .icGrid2
        switch currentColumn {
        case .one:
            gridIconImage = .icGrid1
        case .two:
            gridIconImage = .icGrid2
        case .three:
            gridIconImage = .icGrid3
        }
        gridButton.setImage(gridIconImage, for: .normal)
    }

    // MARK: - Public Methods

    func configure(totalCount: Int, hasOwnedItems: Bool, isExcludingOwned: Bool) {
        totalCountLabel.text = "전체 \(totalCount)개"

        checkboxButton.isHidden = !hasOwnedItems
        excludeOwnedLabel.isHidden = !hasOwnedItems

        checkboxButton.isSelected = isExcludingOwned
    }

    // MARK: - Actions

    @objc private func toggleExcludeOwned() {
        delegate?.didToggleExcludeOwned()
    }

    @objc private func gridButtonTapped() {
        currentColumn = currentColumn.next
        UserManager.gridColumnType = currentColumn.rawValue
        updateGridButtonIcon()
        delegate?.didChangeGridColumn(currentColumn)
    }
}
