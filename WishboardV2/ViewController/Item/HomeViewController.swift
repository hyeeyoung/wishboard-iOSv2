//
//  HomeViewController.swift
//  WishboardV2
//
//  Created by gomin on 8/16/24.
//

import Foundation
import UIKit
import SnapKit
import Core

final class HomeViewController: UIViewController, ItemDetailDelegate {
    
    private let homeView = HomeView()
    private let viewModel = HomeViewModel()
    
    private let backgroundDimView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        self.navigationController?.navigationBar.isHidden = true
        
        setupNotifications()
        setupUI()
        setupDelegates()
        setupBackgroundDimView()
        setupBottomSheet()
        
        viewModel.fetchItems()
        
        // 앱 이용방법
        guard let isFirstLogin = UserManager.isFirstLogin else { return }
        if isFirstLogin {
            self.showAppGuideSheet()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.refreshItems()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(refreshItems), name: .ItemUpdated, object: nil)
    }
    
    private func setupUI() {
        view.addSubview(homeView)
        homeView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.bottom.equalToSuperview()
        }
        homeView.configure(with: viewModel)
    }
    
    private func setupDelegates() {
        homeView.collectionView.delegate = self
        homeView.toolbar.delegate = self
    }
    
    private func setupBindings() {
        
    }
    
    @objc func refreshItems() {
        viewModel.fetchItems()
    }
    
    func scrollToTop() {
        if homeView.collectionView.numberOfSections > 0, homeView.collectionView.numberOfItems(inSection: 0) > 0 {
            homeView.collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
        }
    }
    
    private func setupBackgroundDimView() {
        backgroundDimView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        backgroundDimView.alpha = 0.0 // 초기에는 투명하게 설정
        view.addSubview(backgroundDimView)
        
        backgroundDimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupBottomSheet() {
        
    }
    
    /// 앱 가이드 시트 노출
    private func showAppGuideSheet() {
        DispatchQueue.main.async {
            let guideVC = AppGuideSheetViewController()
            guideVC.modalPresentationStyle = .overFullScreen // 화면 전체 덮기
            guideVC.modalTransitionStyle = .crossDissolve // 부드러운 애니메이션
            
            guideVC.onDismiss = {
                UserManager.isFirstLogin = false
            }
            self.present(guideVC, animated: true)
        }
    }
}

extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = viewModel.items[indexPath.row]
        let detailViewModel = ItemDetailViewModel(item: item)
        let detailViewController = ItemDetailViewController(viewModel: detailViewModel)
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}

extension HomeViewController: HomeToolBarDelegate {
    func alarmNaviItemTap() {
        let nextVC = AlarmListViewController()
        navigationController?.pushViewController(nextVC, animated: true)
    }
}
