//
//  ItemSelectionBottomBar.swift
//  WishboardV2
//
//  Created by gomin on 2026/09/18.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core

protocol ItemSelectionBottomBarDelegate: AnyObject {
    /// 전체 선택
    func selectionBarDidTapSelectAll()
    /// 선택 해제
    func selectionBarDidTapDeselectAll()
    /// 선택된 아이템 삭제
    func selectionBarDidTapDelete()
}

/// 아이템 다중 선택 모드에서 탭바 대신 노출되는 하단바
final class ItemSelectionBottomBar: UIView {

    static let height: CGFloat = 58

    weak var delegate: ItemSelectionBottomBarDelegate?

    // MARK: - Views

    /// 세이프에어리어 아래까지 배경을 채우되, 컨텐츠는 상단 58 영역에만 배치합니다.
    private let contentView = UIView()

    private let separator = UIView().then {
        $0.backgroundColor = .gray_100
    }

    private let selectAllButton = UIButton(type: .system).then {
        $0.setTitle(SelectionText.selectAll, for: .normal)
        $0.titleLabel?.font = TypoStyle.SuitB2.font
        $0.setTitleColor(.gray_700, for: .normal)
        $0.setTitleColor(.gray_300, for: .disabled)
    }

    private let countLabel = UILabel().then {
        $0.text = SelectionText.emptyDescription
        $0.font = TypoStyle.SuitD2.font
        $0.textColor = .gray_200
        $0.textAlignment = .center
        $0.lineBreakMode = .byTruncatingTail
    }

    private let deleteButton = UIButton(type: .system).then {
        $0.setTitle(SelectionText.delete, for: .normal)
        $0.titleLabel?.font = TypoStyle.SuitB2.font
        $0.setTitleColor(.gray_700, for: .normal)
        $0.setTitleColor(.gray_300, for: .disabled)
    }

    // MARK: - Properties

    private var isSelectionEmpty: Bool = true

    private enum SelectionText {
        static let selectAll = "전체 선택"
        static let deselectAll = "선택 해제"
        static let delete = "삭제"
        static let emptyDescription = "아이템을 선택하세요"
    }

    // MARK: - Initializers

    init() {
        super.init(frame: .zero)
        backgroundColor = .white

        setupViews()
        setupConstraints()
        setupPriorities()
        setupActions()
        configure(selectedCount: 0, hasItems: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        addSubview(contentView)
        contentView.addSubview(separator)
        contentView.addSubview(selectAllButton)
        contentView.addSubview(countLabel)
        contentView.addSubview(deleteButton)
    }

    private func setupConstraints() {
        contentView.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
            make.height.equalTo(ItemSelectionBottomBar.height)
        }

        separator.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
            make.height.equalTo(0.5)
        }

        selectAllButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        deleteButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        countLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualTo(selectAllButton.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualTo(deleteButton.snp.leading).offset(-8)
        }
    }

    private func setupPriorities() {
        // 가운데 문구보다 좌우 버튼이 항상 온전히 보이도록 합니다.
        selectAllButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        deleteButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        countLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    private func setupActions() {
        selectAllButton.addTarget(self, action: #selector(selectAllButtonTapped), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
    }

    // MARK: - Public Methods

    /// - Parameters:
    ///   - selectedCount: 현재 선택된 아이템 수
    ///   - hasItems: 화면에 선택 가능한 아이템이 존재하는지 여부
    func configure(selectedCount: Int, hasItems: Bool) {
        isSelectionEmpty = (selectedCount == 0)

        countLabel.text = isSelectionEmpty
        ? SelectionText.emptyDescription
        : "\(selectedCount)개 아이템 선택됨"

        selectAllButton.setTitle(
            isSelectionEmpty ? SelectionText.selectAll : SelectionText.deselectAll,
            for: .normal
        )
        selectAllButton.isEnabled = hasItems || !isSelectionEmpty
        deleteButton.isEnabled = !isSelectionEmpty
    }

    // MARK: - Button Actions

    @objc private func selectAllButtonTapped() {
        UIDevice.vibrate()
        if isSelectionEmpty {
            delegate?.selectionBarDidTapSelectAll()
        } else {
            delegate?.selectionBarDidTapDeselectAll()
        }
    }

    @objc private func deleteButtonTapped() {
        UIDevice.vibrate()
        delegate?.selectionBarDidTapDelete()
    }
}
