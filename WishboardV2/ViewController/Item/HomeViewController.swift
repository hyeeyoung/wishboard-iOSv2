//
//  HomeViewController.swift
//  WishboardV2
//
//  Created by gomin on 8/16/24.
//

import Foundation
import UIKit
import SnapKit

final class HomeViewController: UIViewController, ItemDetailDelegate {
    
    private let homeView = HomeView()
    private let viewModel = HomeViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        self.navigationController?.navigationBar.isHidden = true
        
        self.view.addSubview(homeView)
        homeView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.bottom.equalToSuperview()
        }
        
        homeView.configure(with: viewModel)
        homeView.collectionView.delegate = self
        homeView.toolbar.delegate = self
        viewModel.fetchItems()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
    }
    
    func refreshItems() {
        viewModel.fetchItems()
    }
    
    func scrollToTop() {
        if homeView.collectionView.numberOfSections > 0, homeView.collectionView.numberOfItems(inSection: 0) > 0 {
            homeView.collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
        }
    }
}

extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = viewModel.items[indexPath.row]
        let detailViewModel = ItemDetailViewModel(item: item)
        let detailViewController = ItemDetailViewController(viewModel: detailViewModel, delegate: self)
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}

extension HomeViewController: HomeToolBarDelegate {
    func alarmNaviItemTap() {
        let nextVC = AlarmListViewController()
        navigationController?.pushViewController(nextVC, animated: true)
    }
}
