//
//  ItemDetailViewController.swift
//  WishboardV2
//
//  Created by gomin on 8/18/24.
//

import Foundation
import UIKit

final class ItemDetailViewController: UIViewController {
    
    private let detailView = ItemDetailView()
    private let viewModel: ItemDetailViewModel
    
    init(viewModel: ItemDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.tabBarController?.tabBar.isHidden = true
        
        self.view.addSubview(detailView)
        detailView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.horizontalEdges.bottom.equalToSuperview()
        }
        
        detailView.configure(with: viewModel)
        detailView.toolbar.delegate = self
    }
}

extension ItemDetailViewController: DetailToolBarDelegate {
    func leftNaviItemTap() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func deleteNaviItemTap() {
        // 아이템 삭제 알럿창
        let alert = AlertViewController(alertType: .deleteItem)
        alert.buttonHandlers = [
            { _ in
                print("아이템 삭제 취소")
            }, { _ in
                print("아이템 삭제")
                // TODO: Item Delete API
            }
        ]
        alert.modalTransitionStyle = .crossDissolve
        alert.modalPresentationStyle = .overFullScreen
        self.present(alert, animated: true, completion: nil)
    }
    
    func modifyNaviItemTap() {
        print("item modify")
    }
}
