//
//  FolderDetailViewController.swift
//  WishboardV2
//
//  Created by gomin on 8/25/24.
//

import Foundation
import UIKit
import SnapKit

final class FolderDetailViewController: UIViewController, ToolBarDelegate {
   
    private let folderView: FolderDetailView
    private let viewModel: FolderDetailViewModel
    private let folderTitle: String
    
    init(folderId: String, folderTitle: String) {
        folderView = FolderDetailView(folderTitle: folderTitle)
        viewModel = FolderDetailViewModel(folderId: folderId)
        self.folderTitle = folderTitle
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        self.navigationController?.navigationBar.isHidden = true
        
        self.view.addSubview(folderView)
        folderView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.horizontalEdges.bottom.equalToSuperview()
        }
        
        folderView.configure(with: viewModel)
        folderView.collectionView.delegate = self
        folderView.toolbar.delegate = self
        viewModel.fetchItems()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
        self.refreshItems()
    }
    
    func leftNaviItemTap() {
        navigationController?.popViewController(animated: true)
    }
    
    func refreshItems() {
        viewModel.fetchItems()
    }
}

extension FolderDetailViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = viewModel.items[indexPath.row]
        if let itemIdx = item.item_id {
            let detailViewController = ItemDetailViewController(id: itemIdx)
            navigationController?.pushViewController(detailViewController, animated: true)
        }
    }
}
