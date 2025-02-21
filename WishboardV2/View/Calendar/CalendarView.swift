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
import Core

final class CalendarView: UIView {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    let calendar = UICalendarView()
    let monthLabel = UILabel().then {
        $0.backgroundColor = .white
        $0.textAlignment = .center
        $0.font = TypoStyle.MontserratH1.font
        $0.textColor = .gray_700
    }
    let tableView = UITableView()
    let dateLabel = UILabel().then {
        $0.font = TypoStyle.SuitH3.font
        $0.textColor = .gray_700
    }
    
    public let emptyLabel = UILabel().then {
        $0.text = "앗, 일정이 없어요!\n상품 일정을 지정하고 알림을 받아보세요!"
        $0.setTypoStyleWithMultiLine(typoStyle: .SuitD2)
        $0.textColor = .gray_200
        $0.numberOfLines = 0
        $0.textAlignment = .center
        $0.isHidden = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(calendar)
        calendar.addSubview(monthLabel)
        
        contentView.addSubview(dateLabel)
        contentView.addSubview(tableView)
        tableView.addSubview(emptyLabel)
    }
    
    private func setupConstraints() {
        
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.bottom.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }
        
        calendar.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            let height = UIScreen.main.bounds.size.height * 0.5
            make.height.equalTo(height)
        }
        monthLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(60)
        }
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(calendar.snp.bottom).offset(32)
            make.leading.equalToSuperview().offset(16)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
            let height = UIScreen.main.bounds.size.height * 0.3
            make.height.equalTo(height)
        }
        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}
