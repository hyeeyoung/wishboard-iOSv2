//
//  TabBarViewController.swift
//  WishboardV2
//
//  Created by gomin on 8/16/24.
//

import Foundation
import UIKit
import Core

class TabBarViewController: UITabBarController {
    let seperator = UIView().then{
        $0.backgroundColor = .gray_100
    }
    
    let wishListVC = HomeViewController()
    let folderVC = FolderViewController()
    let addVC = UIViewController()
    let myPageVC = MypageViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBar.backgroundColor = .white
        self.delegate = self
        
        self.tabBar.addSubview(seperator)
        seperator.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }
        
        // 인스턴스화
        wishListVC.tabBarItem.image = Image.wishlistTab
        folderVC.tabBarItem.image = Image.folderTab
        addVC.tabBarItem.image = Image.addTab
        myPageVC.tabBarItem.image = Image.profileTab
        
        wishListVC.tabBarItem.title = "WISHLIST"
        folderVC.tabBarItem.title = "FOLDER"
        addVC.tabBarItem.title = "ADD"
        myPageVC.tabBarItem.title = "MY"
        
        self.tabBar.tintColor = .gray_700
        self.tabBar.unselectedItemTintColor = .gray_150
        let fontAttributes = [NSAttributedString.Key.font: TypoStyle.MontserratD1.font]
        UITabBarItem.appearance().setTitleTextAttributes(fontAttributes, for: .normal)
        
       // navigationController의 root view 설정
        let nav1 = UINavigationController(rootViewController: wishListVC)
        let nav2 = UINavigationController(rootViewController: folderVC)
        let nav3 = UINavigationController(rootViewController: myPageVC)
    
        setViewControllers([nav1, nav2, addVC, nav3], animated: false)
    }
}

extension TabBarViewController: UITabBarControllerDelegate {
    // 탭바 아이템 선택 감지
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        guard let viewControllers = self.viewControllers else { return true }
        
        // 현재 선택된 탭을 다시 선택하면 최상단으로 이동
        if let navController = viewController as? UINavigationController {
            if let topVC = navController.topViewController as? HomeViewController {
                topVC.scrollToTop()
            } else if let topVC = navController.topViewController as? FolderViewController {
                topVC.scrollToTop()
            }
            return true
        }
        
        // ADD 버튼을 누르면 새로운 화면 Present
        if viewController == viewControllers[2] { // 3번째 탭 (index 2)
            let addViewController = AddViewController(type: .manual) // ADD 메뉴의 화면
            addViewController.modalPresentationStyle = .fullScreen
            
            addViewController.confirmAction = { [weak self] in
                self?.wishListVC.refreshItems()
            }
            
            present(addViewController, animated: true)
            return false // 탭바의 기본 동작을 막음
        }
        
        return true
    }
}
