//
//  CalendarView.swift
//  WishboardV2
//
//  Created by gomin on 9/7/24.
//

import Foundation
import UIKit
import SnapKit
import Then
import Combine
import Core

final class CalendarView: UIView {
    // MARK: - UI Components
    private let scrollView = UIScrollView().then {
        $0.alwaysBounceVertical = true
    }
    
    private let contentView = UIView()

    let toolBar = UIView().then {
        $0.backgroundColor = .white
    }

    let monthLabel = UILabel().then {
        $0.font = TypoStyle.MontserratH1.font
        $0.textAlignment = .center
    }

    let quitButton = UIButton().then {
        $0.setImage(Image.quit, for: .normal)
    }

    private let weekDaysStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.distribution = .fillEqually
    }

    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.sectionInset = .zero
        layout.itemSize = CGSize(width: floor(UIScreen.main.bounds.width / 7), height: 50)

        return UICollectionView(frame: .zero, collectionViewLayout: layout).then {
            $0.isScrollEnabled = true
            $0.isPagingEnabled = true
            $0.alwaysBounceHorizontal = true
        }
    }()

    let selectedDateLabel = UILabel().then {
        $0.font = TypoStyle.SuitH3.font
        $0.textColor = .gray_700
    }

    let tableView = UITableView().then {
        $0.register(NoticeTableViewCell.self, forCellReuseIdentifier: "NoticeTableViewCell")
        $0.separatorStyle = .none
    }

    private let emptyView = UIView().then {
        $0.isHidden = true
    }

    private let emptyImageView = UIImageView().then {
        $0.image = Image.notiLarge
        $0.contentMode = .scaleAspectFit
    }

    private let emptyLabel = UILabel().then {
        $0.text = "앗, 일정이 없어요!\n상품 일정을 지정하고 알림을 받아보세요!"
        $0.numberOfLines = 0
        $0.textColor = .gray_200
        $0.setTypoStyleWithMultiLine(typoStyle: .SuitB3)
        $0.textAlignment = .center
    }
    
    private let firstSeparatorView = UIView().then {
        $0.backgroundColor = .gray_100
    }
    
    private let secondSeparatorView = UIView().then {
        $0.backgroundColor = .gray_100
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupUI() {
        addSubview(scrollView)
        scrollView.addSubview(contentView)

        [toolBar, weekDaysStackView, collectionView, firstSeparatorView, secondSeparatorView, selectedDateLabel, tableView, emptyView].forEach {
            contentView.addSubview($0)
        }

        toolBar.addSubview(monthLabel)
        toolBar.addSubview(quitButton)

        let weekDays = ["Sun", "Mon", "Tue", "Wen", "Thu", "Fri", "Sat"]
        weekDays.forEach { day in
            let label = UILabel().then {
                $0.text = day
                $0.textAlignment = .center
                $0.font = TypoStyle.MontserratB2.font
            }
            weekDaysStackView.addArrangedSubview(label)
        }

        emptyView.addSubview(emptyImageView)
        emptyView.addSubview(emptyLabel)

        setupConstraints()
    }

    private func setupConstraints() {
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        toolBar.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(42)
            $0.top.equalToSuperview()
        }

        monthLabel.snp.makeConstraints { $0.center.equalToSuperview() }
        quitButton.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }

        weekDaysStackView.snp.makeConstraints {
            $0.top.equalTo(toolBar.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(20)
        }
        collectionView.snp.makeConstraints {
            $0.top.equalTo(weekDaysStackView.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(303)
        }
        firstSeparatorView.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.top)
            make.height.equalTo(0.52)
            make.leading.trailing.equalToSuperview()
        }
        secondSeparatorView.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.bottom)
            make.height.equalTo(0.52)
            make.leading.trailing.equalToSuperview()
        }
        selectedDateLabel.snp.makeConstraints {
            $0.top.equalTo(collectionView.snp.bottom).offset(32)
            $0.leading.equalToSuperview().offset(16)
        }

        tableView.snp.makeConstraints {
            $0.top.equalTo(selectedDateLabel.snp.bottom).offset(16)
            $0.leading.trailing.bottom.equalToSuperview().inset(16)
            $0.height.equalTo(200)
        }

        emptyView.snp.makeConstraints {
            $0.edges.equalTo(tableView)
        }

        emptyImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(40)
            $0.width.equalTo(74)
            $0.height.equalTo(75)
        }

        emptyLabel.snp.makeConstraints {
            $0.top.equalTo(emptyImageView.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
        }
    }

    // MARK: - Public
    public func configureSelectedLabel(_ rawDate: Date) {
        let formattedDate = formatDate(rawDate)
        selectedDateLabel.text = "\(formattedDate) 일정"
    }

    public func setEmptyView(isHidden: Bool) {
        emptyView.isHidden = isHidden
        tableView.isHidden = !isHidden
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일"
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter.string(from: date)
    }
}
