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
import ApplicationLibrary

final class AlarmListViewController: UIViewController, ItemDetailDelegate {
    func refreshItems() {
        print("")
    }
    
    private var viewModel = AlarmListViewModel()
    private var noticeView = AlarmListView()
    private var cancellables = Set<AnyCancellable>()
    /// 사파리로 띄운 링크. 첫 로딩에 실패했을 때 어떤 주소였는지 남기려고 들고 있습니다.
    private var openedLinkURLString: String?
    
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
        super.viewWillAppear(animated)
        AnalyticsManager.shared.log(.screenView(name: .notification))
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
                self?.noticeView.refreshControl.endRefreshing()
            }
            .store(in: &cancellables)
        
        noticeView.refreshAction = { [weak self] in
            self?.viewModel.fetchItems(isRefreshing: true)
        }

        // 알림 리스트 조회 동안 로딩뷰 노출
        viewModel.$isLoading
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] isLoading in
                self?.noticeView.setLoading(isLoading)
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
        UIDevice.vibrate()
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = viewModel.noticeItems[indexPath.row]
        // 알림 읽음 처리
        viewModel.updateReadState(item)
        
        // Safari 화면 이동
        if let link = item.link, let url = NSURL(string: link) {
            if !(["http", "https"].contains(url.scheme?.lowercased())) {
                SnackBar.shared.show(type: .shoppingLinkNotExist)
                AnalyticsManager.shared.log(
                    .itemLinkOpenFailed(url: link, source: .notificationInvalidURL)
                )
                return
            }

            // 첫 로딩 실패를 남기려면 띄울 때의 주소를 들고 있어야 합니다.
            self.openedLinkURLString = link

            let linkView: SFSafariViewController = SFSafariViewController(url: url as URL)
            linkView.delegate = self
            self.present(linkView, animated: true, completion: nil)
        } else {
            SnackBar.shared.show(type: .shoppingLinkNotExist)
            // 주소가 비어 있을 수도 있어 빈 문자열이라도 그대로 남깁니다.
            AnalyticsManager.shared.log(
                .itemLinkOpenFailed(url: item.link ?? "", source: .notificationInvalidURL)
            )
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
        UIDevice.vibrate()
        self.navigationController?.popViewController(animated: true)
    }
    
    func calendarNaviItemTap() {
        UIDevice.vibrate()
        let nextVC = UINavigationController(rootViewController: CalendarViewController())
        nextVC.modalPresentationStyle = .fullScreen
        self.present(nextVC, animated: true, completion: nil)
    }
    
}

// MARK: - 링크 열기 실패 기록

extension AlarmListViewController: SFSafariViewControllerDelegate {

    /// 사파리가 첫 페이지를 못 불러온 경우입니다.
    ///
    /// 첫 로딩만 알려 주므로, 로딩은 됐는데 이후 이동에서 멈추는 경우는 여기 잡히지 않습니다.
    func safariViewController(_ controller: SFSafariViewController,
                              didCompleteInitialLoad didLoadSuccessfully: Bool) {
        guard !didLoadSuccessfully, let urlString = openedLinkURLString else { return }

        AnalyticsManager.shared.log(
            .itemLinkOpenFailed(url: urlString, source: .notificationLoadFailed)
        )
    }

    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        openedLinkURLString = nil
    }
}
