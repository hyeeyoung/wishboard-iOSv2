//
//  NoticeViewController.swift
//  WishboardV2
//
//  Created by gomin on 8/29/24.
//

import Foundation
import UIKit
import Combine

final class NoticeViewController: UIViewController, ItemDetailDelegate {
    func refreshItems() {
        print("")
    }
    
    
    private var viewModel = NoticeViewModel()
    private var noticeView = NoticeView()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        viewModel.fetchItems()
    }
    
    override func viewWillAppear(_ animated: Bool) {
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
    
    private func setupBindings() {
        viewModel.$noticeItems
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.noticeView.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
}

// MARK: - UITableViewDataSource
extension NoticeViewController: UITableViewDataSource {
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
        
        // 아이템 디테일 화면으로 이동
        Task {
            do {
                let wishItem = try await viewModel.fetchItemDetail(id: item.id)
                
                let detailViewModel = ItemDetailViewModel(item: wishItem)
                let detailViewController = ItemDetailViewController(viewModel: detailViewModel, delegate: self)
                navigationController?.pushViewController(detailViewController, animated: true)
            } catch {
                throw error
            }
        }
    }
}

// MARK: - UITableViewDelegate
extension NoticeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 112
    }
}
