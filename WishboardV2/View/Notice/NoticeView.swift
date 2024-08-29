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

final class NoticeView: UIView {
    let toolBar = BaseToolBar()
    let tableView = UITableView()
    
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
    }
    
    private func setupConstraints() {
        toolBar.configure(title: "알림")
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(toolBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
}
