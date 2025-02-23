//
//  AlarmListViewController.swift
//  WishboardV2
//
//  Created by gomin on 8/29/24.
//

import Foundation
import UIKit
import Combine
import SafariServices
import Core

final class AlarmListViewController: UIViewController, ItemDetailDelegate {
    func refreshItems() {
        print("")
    }
    
    private var viewModel = AlarmListViewModel()
    private var noticeView = AlarmListView()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDelegates()
        setupBindings()
        viewModel.fetchItems()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
        self.tabBarController?.tabBar.isHidden = false
        super.viewWillAppear(animated)
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        self.view.addSubview(noticeView)
        noticeView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.horizontalEdges.bottom.equalToSuperview()
        }
        self.setupTableView()
    }
    
    private func setupTableView() {
        noticeView.tableView.dataSource = self
        noticeView.tableView.delegate = self
        noticeView.tableView.register(NoticeTableViewCell.self, forCellReuseIdentifier: NoticeTableViewCell.reuseIdentifier)
    }
    
    private func setupDelegates() {
        noticeView.toolBar.delegate = self
    }
    
    private func setupBindings() {
        viewModel.$noticeItems
            .receive(on: RunLoop.main)
            .sink { [weak self] items in
                self?.noticeView.emptyLabel.isHidden = !(items.isEmpty)
                self?.noticeView.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
}

// MARK: - UITableViewDataSource
extension AlarmListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.noticeItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NoticeTableViewCell", for: indexPath) as? NoticeTableViewCell else {
            return UITableViewCell()
        }
        let item = viewModel.noticeItems[indexPath.row]
        cell.configure(with: item)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = viewModel.noticeItems[indexPath.row]
        // 알림 읽음 처리
        viewModel.updateReadState(item)
        
        // Safari 화면 이동
        if let link = item.link, let url = NSURL(string: link) {
            let linkView: SFSafariViewController = SFSafariViewController(url: url as URL)
            self.present(linkView, animated: true, completion: nil)
        } else {
            SnackBar.shared.show(type: .ShoppingLink)
        }
        
    }
}

// MARK: - UITableViewDelegate
extension AlarmListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 112
    }
}

extension AlarmListViewController: AlarmToolBarDelegate {
    func leftNaviItemTap() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func calendarNaviItemTap() {
        let nextVC = CalendarViewController()
        self.navigationController?.pushViewController(nextVC, animated: true)
    }
    
}
