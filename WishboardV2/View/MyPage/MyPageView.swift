//
//  MyPageView.swift
//  WishboardV2
//
//  Created by gomin on 8/24/24.
//

import Foundation
import UIKit
import Core

protocol MypageViewDelegate: AnyObject {
    func didSelectSetting(at indexPath: IndexPath)
}

final class MypageView: UIView {
    
    private let toolBar = BaseToolBar()
    let tableView = UITableView(frame: .zero, style: .grouped)
    weak var delegate: MypageViewDelegate?
    
    private var settings: [Setting] = []
    private var user: User?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        addSubview(toolBar)
        
        tableView.register(SettingTableViewCell.self, forCellReuseIdentifier: SettingTableViewCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        addSubview(tableView)
        
        toolBar.configure(title: "마이페이지")
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(toolBar.snp.bottom)
            make.horizontalEdges.bottom.equalToSuperview()
        }
    }
    
    func updateProfile(with user: User) {
        self.user = user
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
    
    func updateSettings(with settings: [Setting]) {
        self.settings = settings
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension MypageView: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 // 설정 항목들을 포함하는 하나의 섹션
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingTableViewCell.identifier, for: indexPath) as! SettingTableViewCell
        let setting = settings[indexPath.row]
        cell.configure(with: setting)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 1, 7:
            return 48 + 6
        default:
            return 48
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let user = user else { return nil }
        let headerView = ProfileHeaderView()
        headerView.configure(with: user)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 148 // 프로필 헤더뷰의 높이
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        UIDevice.vibrate()
        delegate?.didSelectSetting(at: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
