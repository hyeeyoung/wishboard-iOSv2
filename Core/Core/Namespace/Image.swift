//
//  Image.swift
//  Wishboard
//
//  Created by gomin on 2023/02/23.
//

import Foundation
import UIKit

public enum Image{
    
    // MARK: - Icons
    // folder
    public static let addFolder = UIImage(named: "addFolder")!  // at Share Extension
    public static let newFolder = UIImage(named: "ic_new_folder")!  // at app
    public static let reorderFolder = UIImage(named: "folder_reorder")!
    public static let arrowRetry = UIImage(named: "arrow-retry")!
    public static let drag = UIImage(named: "drag")!
    
    // arrow
    public static let arrowRight = UIImage(named: "arrow_right")!
    
    // camera
    public static let cameraGray = UIImage(named: "camera_gray")!
    public static let cameraGreen = UIImage(named: "camera_green")!
    
    // check
    public static let checkWhite = UIImage(named: "check_white")!
    public static let checkGreen = UIImage(named: "check")!
    
    // Alarm
    public static let notice = UIImage(named: "notice")!
    
    // 소장템 제외
    public static let ownedCircle = UIImage(named: "owned_circle")!
    public static let ownedCircleCheck = UIImage(named: "owned_circle_check")!
    
    // 그리드 Grid
    public static let grid1 = UIImage(named: "ic_grid1")!
    public static let grid2 = UIImage(named: "ic_grid2")!
    public static let grid3 = UIImage(named: "ic_grid3")!
    
    // cart
    public static let cartIcon = UIImage(named: "cart")!
    public static let cartPlus = UIImage(named: "ic_cart_plus")!
    public static let cartMinus = UIImage(named: "ic_cart_minus")!
    
    public static let goBack = UIImage(named: "goBack")!
    public static let calender = UIImage(named: "ic_calendar")!
    
    // menu
    public static let menu = UIImage(named: "ic_menu")!
    public static let more = UIImage(named: "ic_more")!
    
    // noti
    public static let noti = UIImage(named: "ic_noti")!
    public static let notiLarge = UIImage(named: "noti_large")!
    public static let notiClear = UIImage(named: "noti_clear")!
    
    public static let imageBackground = UIImage(named: "image_background")!
    
    // register
    public static let locked = UIImage(named: "locked")!
    public static let loveLetter = UIImage(named: "love-letter")!
    public static let wavingHand = UIImage(named: "twemoji_waving-hand")!
    
    public static let pencil = UIImage(named: "pencil")!
    public static let trash = UIImage(named: "trash")!
    public static let quit = UIImage(named: "x")!
    
    public static let whiteQuit = UIImage(named: "white_x")!
    
    // profile
    public static let defaultProfile = UIImage(named: "defaultProfile")!
    
    // MARK: - How to Images
    public static let how1 = UIImage(named: "how_1")!
    public static let how2 = UIImage(named: "how_2")!
    public static let how3 = UIImage(named: "how_3")!
    
    // MARK: - Logo
    public static let appLogo = UIImage(named: "appLogo")!
    public static let homeAppLogo = UIImage(named: "home_app_logo")!
    public static let blackLogo = UIImage(named: "blackLogo")!
    public static let wishboardLogo = UIImage(named: "WishBoardLogo")!
    // 로고 신규 버전 (GUI 3.0.0)
    public static let homeLogo = UIImage(named: "home_logo")!
    public static let splashLogo = UIImage(named: "splash_logo")!
    public static let onboardingLogo = UIImage(named: "onboarding_logo")!
    
    // MARK: - Tab Bar Icons
    public static let addTab = UIImage(named: "add")!
    public static let folderTab = UIImage(named: "folder")!
    public static let profileTab = UIImage(named: "profile")!
    public static let wishlistTab = UIImage(named: "wishlist")!
    
    // MARK: - Empty View
    public static let emptyView = UIImage(named: "emptyView")!
}
