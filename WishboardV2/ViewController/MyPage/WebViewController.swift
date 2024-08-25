//
//  WebViewController.swift
//  WishboardV2
//
//  Created by gomin on 8/24/24.
//

import Foundation
import UIKit
import SnapKit
import Then
import WebKit
import Core

// MARK: 링크 이동 후 보이는 페이지
final class WebViewController: UIViewController, WKUIDelegate {
    // MARK: - Views
    let backView = UIView().then{
        $0.backgroundColor = .white
    }
    let navigationBar = UIView().then{
        $0.backgroundColor = .white
    }
    let operatorLine = UIView().then{
        $0.backgroundColor = .gray_100
    }
    let titleLabel = UILabel().then{
        $0.setTypoStyleWithSingleLine(typoStyle: .SuitH3)
    }
    let backButton = UIButton().then{
        $0.setImage(Image.goBack, for: .normal)
    }
    
    // Properties
    var webView: WKWebView!
    var webURL: String!
    
    // MARK: - Life Cycles
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        view = backView
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        self.tabBarController?.tabBar.isHidden = true
        
        guard let url = self.webURL else {return}
        let myURL = URL(string: url)
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
        
        setUpView()
        backButton.addTarget(self, action: #selector(goBackButtonDidTap), for: .touchUpInside)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
    // MARK: - Actions
    @objc func goBackButtonDidTap() {
        UIDevice.vibrate()
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Functions
    func setUpView() {
        self.backView.addSubview(navigationBar)
        self.backView.addSubview(operatorLine)
        self.backView.addSubview(webView)
        
        navigationBar.addSubview(titleLabel)
        navigationBar.addSubview(backButton)
        
        navigationBar.snp.makeConstraints { make in
            make.height.equalTo(51)
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide)
        }
        operatorLine.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(navigationBar.snp.bottom)
        }
        titleLabel.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
        }
        backButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.equalTo(18)
            make.height.equalTo(14)
            make.leading.equalToSuperview().offset(16)
        }
        webView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(operatorLine.snp.bottom)
        }
    }
    
    func setUpTitle(_ titleStr: String) {
        self.titleLabel.text = titleStr
    }
    
}
