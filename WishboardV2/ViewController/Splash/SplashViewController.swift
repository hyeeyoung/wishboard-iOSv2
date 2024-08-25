//
//  SplashViewController.swift
//  WishboardV2
//
//  Created by gomin on 7/27/24.
//

import Foundation
import UIKit
import Core

class SplashViewController: UIViewController {
    
    private let logo = UIImageView().then {
        $0.image = Image.wishboardLogo
    }
    private let debugVersion = UILabel().then {
        $0.text = "Version: \(Bundle.appVersion)(\(Bundle.appBuildVersion))\nServer: \(NetworkMacro.BaseURL)"
        $0.numberOfLines = 0
        $0.font = UIFont.systemFont(ofSize: 10)
        $0.textColor = .gray_700
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white

        setupUI()
    }

    private func setupUI() {
        self.view.addSubview(logo)
        
        logo.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(56)
        }
        
        #if DEBUG
        self.setUpVersionLabel("dev")
        #endif
        
    }
    
    private func setUpVersionLabel(_ version: String) {
        self.view.addSubview(debugVersion)
        
        debugVersion.snp.makeConstraints { make in
            make.leading.equalTo(logo)
            make.bottom.equalToSuperview().inset(50)
        }
    }

}
