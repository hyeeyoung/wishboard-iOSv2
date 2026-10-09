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
    /// '소장템 제외' 체크박스를 쓰는 화면에서만 구현합니다. (폴더 상세)
    func didToggleExcludeOwned()
    /// 필터 딱지를 쓰는 화면에서만 구현합니다. (홈화면)
    func didTapFilterChip()
    func didChangeGridColumn(_ column: GridColumnType)
}

extension HomeStickyHeaderDelegate {
    func didToggleExcludeOwned() {}
    func didTapFilterChip() {}
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
    }

    private let excludeOwnedLabel = UILabel().then {
        $0.text = "소장템 제외"
        $0.setTypoStyleWithSingleLine(typoStyle: .SuitD3)
        $0.textColor = .gray_200
    }

    /// 홈화면에서 '소장템 제외' 체크박스 대신 노출되는 필터 딱지
    private let filterChipView = UIView().then {
        // 이 화면에서만 쓰는 색이라 디자인 시스템에는 넣지 않습니다.
        $0.backgroundColor = UIColor(red: 243/255, green: 243/255, blue: 243/255, alpha: 1)
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
        $0.isHidden = true
    }

    private let filterChipLabel = UILabel().then {
        $0.font = TypoStyle.SuitB5.font
        $0.textColor = .gray_600
        $0.isUserInteractionEnabled = false
    }

    private let filterChipArrow = UIImageView().then {
        $0.image = UIImage(systemName: "chevron.down")
        $0.tintColor = .gray_300
        $0.contentMode = .scaleAspectFit
        $0.isUserInteractionEnabled = false
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
        addSubview(filterChipView)
        filterChipView.addSubview(filterChipLabel)
        filterChipView.addSubview(filterChipArrow)
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

        // 딱지의 크기는 글자와 여백으로 정해집니다.
        filterChipView.snp.makeConstraints { make in
            make.trailing.equalTo(gridButton.snp.leading).offset(-10)
            make.centerY.equalToSuperview()
        }

        filterChipLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.verticalEdges.equalToSuperview().inset(4)
        }

        filterChipArrow.snp.makeConstraints { make in
            make.leading.equalTo(filterChipLabel.snp.trailing).offset(6)
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalTo(filterChipLabel)
            make.width.equalTo(8)
            make.height.equalTo(4)
        }
    }

    private func setupActions() {
        checkboxButton.addTarget(self, action: #selector(toggleExcludeOwned), for: .touchUpInside)
        gridButton.addTarget(self, action: #selector(gridButtonTapped), for: .touchUpInside)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleExcludeOwned))
        excludeOwnedLabel.isUserInteractionEnabled = true
        excludeOwnedLabel.addGestureRecognizer(tapGesture)

        let chipTapGesture = UITapGestureRecognizer(target: self, action: #selector(filterChipTapped))
        filterChipView.addGestureRecognizer(chipTapGesture)
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

    /// '소장템 제외' 체크박스를 쓰는 화면용 (폴더 상세)
    func configure(totalCount: Int, isExcludingOwned: Bool) {
        totalCountLabel.text = "전체 \(totalCount)개"
        checkboxButton.isSelected = isExcludingOwned
        setUsesFilterChip(false)
    }

    /// 필터 딱지를 쓰는 화면용 (홈화면)
    func configure(totalCount: Int, filter: HomeItemFilter) {
        totalCountLabel.text = "전체 \(totalCount)개"
        filterChipLabel.text = filter.chipTitle
        setUsesFilterChip(true)
    }

    /// 셀이 재사용되어도 두 가지가 같이 보이지 않도록 한쪽만 남깁니다.
    private func setUsesFilterChip(_ usesFilterChip: Bool) {
        filterChipView.isHidden = !usesFilterChip
        checkboxButton.isHidden = usesFilterChip
        excludeOwnedLabel.isHidden = usesFilterChip
    }

    // MARK: - Actions

    @objc private func toggleExcludeOwned() {
        delegate?.didToggleExcludeOwned()
    }

    @objc private func filterChipTapped() {
        UIDevice.vibrate()
        delegate?.didTapFilterChip()
    }

    @objc private func gridButtonTapped() {
        currentColumn = currentColumn.next
        UserManager.gridColumnType = currentColumn.rawValue
        updateGridButtonIcon()
        delegate?.didChangeGridColumn(currentColumn)
    }
}
