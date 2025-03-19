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
    var collectionView: UICollectionView!
    var tableView: UITableView!
    var scrollView: UIScrollView!
    let toolBar = UIView().then {
        $0.backgroundColor = .white
    }
    var monthLabel: UILabel!
    let quitButton = UIButton().then {
        $0.setImage(Image.quit, for: .normal)
    }
    var weekDaysStackView: UIStackView!
    let selectedDateLabel = UILabel().then {
        $0.font = TypoStyle.SuitH3.font
        $0.textColor = .gray_700
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        addSubview(scrollView)

        let contentView = UIView()
        scrollView.addSubview(contentView)

        monthLabel = UILabel()
        monthLabel.font = TypoStyle.MontserratH1.font
        monthLabel.textAlignment = .center
        
        toolBar.addSubview(monthLabel)
        toolBar.addSubview(quitButton)
        contentView.addSubview(toolBar)
        
        let weekDays = ["Sun", "Mon", "Tue", "Wen", "Thu", "Fri", "Sat"]
        weekDaysStackView = UIStackView()
        weekDaysStackView.axis = .horizontal
        weekDaysStackView.distribution = .fillEqually

        for day in weekDays {
            let label = UILabel()
            label.text = day
            label.textAlignment = .center
            label.font = TypoStyle.MontserratB2.font
            weekDaysStackView.addArrangedSubview(label)
        }
        contentView.addSubview(weekDaysStackView)

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.sectionInset = .zero
        let cellWidth = floor(UIScreen.main.bounds.width / 7)
        layout.itemSize = CGSize(width: cellWidth, height: 50)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        contentView.addSubview(collectionView)
        
        collectionView.isScrollEnabled = true
        collectionView.isPagingEnabled = true
        collectionView.alwaysBounceHorizontal = true // 좌우 스크롤 활성화
        
        contentView.addSubview(selectedDateLabel)

        tableView = UITableView()
        tableView.register(NoticeTableViewCell.self, forCellReuseIdentifier: "NoticeTableViewCell")
        tableView.separatorStyle = .none
        contentView.addSubview(tableView)
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }
        toolBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview()
            make.height.equalTo(42)
        }
        monthLabel.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
        }
        quitButton.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.width.height.equalTo(24)
            make.centerY.equalToSuperview()
        }
        weekDaysStackView.snp.makeConstraints { make in
            make.top.equalTo(toolBar.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(20)
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(weekDaysStackView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(303)
        }
        selectedDateLabel.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.bottom).offset(32)
            make.leading.equalToSuperview().offset(16)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(selectedDateLabel.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalToSuperview().inset(16)
            make.height.equalTo(200)
        }
    }
    
    public func configureSelectedLabel(_ rawDate: Date) {
        let formattedDate = formatDate(rawDate)
        selectedDateLabel.text = "\(formattedDate) 일정"
    }
    
    private func formatDate(_ date: Date) -> String {
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "M월 d일"
        outputFormatter.locale = Locale(identifier: "ko_KR")
        outputFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")

        return outputFormatter.string(from: date)
    }
}
