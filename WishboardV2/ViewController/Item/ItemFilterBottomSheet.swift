//
//  ItemFilterBottomSheet.swift
//  WishboardV2
//
//  Created by gomin on 10/9/26.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core

// MARK: - 필터 한 줄

final class ItemFilterCell: UITableViewCell {

    static let reuseIdentifier = "ItemFilterCell"
    static let height: CGFloat = 56

    /// 선택 표시 아이콘 크기
    private static let checkIconSize: CGFloat = 24

    private let titleLabel = UILabel().then {
        $0.font = TypoStyle.SuitB3.font
        $0.textColor = .gray_700
    }

    /// 미선택 상태의 빈 원
    private let emptyCircleView = UIImageView().then {
        $0.image = Image.circle24
        $0.contentMode = .scaleAspectFit
    }

    private let checkImageView = UIImageView().then {
        $0.image = Image.checkGreenCircle24
        $0.contentMode = .scaleAspectFit
        $0.isHidden = true
    }

    private let separator = UIView().then {
        $0.backgroundColor = .gray_100
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .white

        contentView.addSubview(titleLabel)
        contentView.addSubview(emptyCircleView)
        contentView.addSubview(checkImageView)
        contentView.addSubview(separator)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        emptyCircleView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ItemFilterCell.checkIconSize)
        }

        checkImageView.snp.makeConstraints { make in
            make.edges.equalTo(emptyCircleView)
        }

        // 줄과 줄 사이에만 두므로 마지막 줄에서는 숨깁니다.
        separator.snp.makeConstraints { make in
            make.horizontalEdges.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with filter: HomeItemFilter, isSelected: Bool, showsSeparator: Bool) {
        titleLabel.text = filter.listTitle
        checkImageView.isHidden = !isSelected
        emptyCircleView.isHidden = isSelected
        separator.isHidden = !showsSeparator
    }
}

// MARK: - 시트 본문

final class ItemFilterSheetView: UIView {

    /// 제목과 닫기 버튼이 있는 상단 영역의 높이
    static let headerHeight: CGFloat = 50

    let tableView = UITableView().then {
        $0.separatorStyle = .none
        $0.backgroundColor = .white
        $0.rowHeight = ItemFilterCell.height
        $0.showsVerticalScrollIndicator = false
    }

    let closeButton = UIButton(type: .system).then {
        $0.setImage(Image.quit, for: .normal)
        $0.tintColor = .gray_700
    }

    private let titleLabel = UILabel().then {
        $0.text = "필터"
        $0.font = TypoStyle.SuitH3.font
        $0.textColor = .gray_700
        $0.textAlignment = .center
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.cornerRadius = 20
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        clipsToBounds = true

        addSubview(titleLabel)
        addSubview(closeButton)
        addSubview(tableView)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.centerX.equalToSuperview()
        }

        closeButton.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-16)
        }

        tableView.register(ItemFilterCell.self, forCellReuseIdentifier: ItemFilterCell.reuseIdentifier)
        tableView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ItemFilterSheetView.headerHeight)
            make.horizontalEdges.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - 필터 선택 바텀시트

/// 홈화면의 목록 필터를 고르는 바텀시트.
///
/// 필터를 고르면 바로 닫히고, 고른 값을 `onSelect` 로 알립니다.
final class ItemFilterBottomSheetViewController: UIViewController {

    /// 시트가 화면을 덮을 수 있는 최대 비율. 필터가 늘어나도 너무 커지지 않게 합니다.
    private static let maxHeightRatio: CGFloat = 0.7
    /// 마지막 줄 아래 여백
    private static let listBottomInset: CGFloat = 16
    /// 시트가 내려가 있을 때의 위치. 화면 높이만큼 내려 두면 어떤 높이에서도 가려집니다.
    private static let hiddenOffset: CGFloat = UIScreen.main.bounds.height

    private let backgroundDimView = UIView()
    private let sheetView = ItemFilterSheetView()

    private let filters = HomeItemFilter.allCases
    private var selectedFilter: HomeItemFilter

    /// 필터를 고르면 호출됩니다.
    var onSelect: ((HomeItemFilter) -> Void)?

    // MARK: - Initializers

    init(selectedFilter: HomeItemFilter) {
        self.selectedFilter = selectedFilter
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showSheet()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .clear

        backgroundDimView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        backgroundDimView.alpha = 0
        view.addSubview(backgroundDimView)
        backgroundDimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 높이는 안전 영역이 잡히는 시점(viewDidAppear)에 다시 맞춥니다.
        // 내려가 있는 위치는 화면 높이만큼으로 넉넉히 두어, 높이가 바뀌어도 어긋나지 않게 합니다.
        view.addSubview(sheetView)
        sheetView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(sheetHeight)
            make.bottom.equalToSuperview().offset(ItemFilterBottomSheetViewController.hiddenOffset)
        }

        sheetView.tableView.dataSource = self
        sheetView.tableView.delegate = self
    }

    private func setupActions() {
        sheetView.closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dimViewTapped))
        backgroundDimView.addGestureRecognizer(tapGesture)
    }

    /// 상단바 + 줄 높이로 정하되, 화면을 너무 덮지 않도록 제한합니다.
    private var sheetHeight: CGFloat {
        let listHeight = CGFloat(filters.count) * ItemFilterCell.height
        let safeAreaBottom = view.safeAreaInsets.bottom
        let contentHeight = ItemFilterSheetView.headerHeight
            + listHeight
            + ItemFilterBottomSheetViewController.listBottomInset
            + safeAreaBottom

        let maxHeight = UIScreen.main.bounds.height * ItemFilterBottomSheetViewController.maxHeightRatio
        return min(contentHeight, maxHeight)
    }

    // MARK: - Animation

    private func showSheet() {
        // 안전 영역이 잡힌 뒤라 여기서 높이를 한 번 더 맞춰 줍니다.
        sheetView.snp.updateConstraints { make in
            make.height.equalTo(sheetHeight)
        }
        view.layoutIfNeeded()

        UIView.animate(withDuration: 0.3) {
            self.backgroundDimView.alpha = 1
            self.sheetView.snp.updateConstraints { make in
                make.bottom.equalToSuperview().offset(0)
            }
            self.view.layoutIfNeeded()
        }
    }

    private func dismissSheet(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.3, animations: {
            self.backgroundDimView.alpha = 0
            self.sheetView.snp.updateConstraints { make in
                make.bottom.equalToSuperview().offset(ItemFilterBottomSheetViewController.hiddenOffset)
            }
            self.view.layoutIfNeeded()
        }) { _ in
            self.dismiss(animated: false) {
                completion?()
            }
        }
    }

    // MARK: - Actions

    @objc private func closeButtonTapped() {
        UIDevice.vibrate()
        dismissSheet()
    }

    @objc private func dimViewTapped() {
        dismissSheet()
    }
}

// MARK: - 필터 목록

extension ItemFilterBottomSheetViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filters.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ItemFilterCell.reuseIdentifier,
            for: indexPath
        ) as? ItemFilterCell,
              indexPath.row < filters.count else {
            return UITableViewCell()
        }

        let filter = filters[indexPath.row]
        cell.configure(
            with: filter,
            isSelected: filter == selectedFilter,
            showsSeparator: indexPath.row < filters.count - 1
        )
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < filters.count else { return }
        let filter = filters[indexPath.row]

        UIDevice.vibrate()
        selectedFilter = filter
        tableView.reloadData()

        // 고르면 시트가 닫히고 목록이 새로 조회됩니다.
        dismissSheet { [weak self] in
            self?.onSelect?(filter)
        }
    }
}
