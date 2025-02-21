//
//  NoticeView.swift
//  WishboardV2
//
//  Created by gomin on 8/29/24.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core

final class AlarmListView: UIView {
    let toolBar = AlarmToolBar()
    let tableView = UITableView()
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
        addSubview(toolBar)
        addSubview(tableView)
        addSubview(emptyLabel)
    }
    
    private func setupConstraints() {
        toolBar.configure(title: "알림")
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(toolBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}
