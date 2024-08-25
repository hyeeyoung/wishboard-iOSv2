//
//  ShareViewController.swift
//  Share Extension
//
//  Created by gomin on 8/25/24.
//

import UIKit
import Core
import WBNetwork

class ShareViewController: UIViewController {
    
    private let shareView = ShareView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(shareView)
        shareView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

}
