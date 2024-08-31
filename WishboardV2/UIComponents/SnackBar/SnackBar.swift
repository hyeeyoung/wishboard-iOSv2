//
//  SnackBar.swift
//  WishboardV2
//
//  Created by gomin on 8/24/24.
//

import Foundation
import UIKit
import Core

final class SnackBar {
    
    static let shared = SnackBar()
    private var isShowing = false // 스낵바 표시 여부를 추적
    
    let SNACKBAR_HEIGHT = 48
    let SNACKBAR_INTERVAL = 34
    let TRANSLATION_Y: CGFloat
    
    var window: UIViewController?
    var type: SnackBarType?
    
    // TODO: Share-Extension일 때 ERROR
    public init(in viewController: UIViewController? = nil) {
        #if WISHBOARD_APP
        self.window = UIApplication.shared.keyWindow?.rootViewController
        #else
        self.window = viewController
        #endif
        
        let translationY = SNACKBAR_HEIGHT + SNACKBAR_INTERVAL
        TRANSLATION_Y = CGFloat(-translationY)
    }
    
    // MARK: Views
    let backgroundView = UIView().then{
        $0.backgroundColor = .gray_700
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 24
    }
    var title = UILabel().then{
        $0.textColor = .white
        $0.setTypoStyleWithSingleLine(typoStyle: .SuitD2)
        $0.textAlignment = .center
        $0.numberOfLines = 0
    }
    
    // MARK: Methods
    func show(type: SnackBarType) {
        self.type = type
        
        // 스낵바가 이미 표시 중이면 중복 표시하지 않습니다.
        guard !isShowing else {
            return
        }
        
        isShowing = true // 스낵바가 표시 중임을 표시
        
        setSnackBarUI()
        performAnimation()
        
    }
    /// 스낵바의 UI 설정
    private func setSnackBarUI() {
        setSnackBarContent()
        addSnackBarSubview()
        setSnackBarConstraints()
    }
    /// 스낵바의 문구 내용 설정
    private func setSnackBarContent() {
        guard let type = self.type else {return}
        title.text = type.message
    }
    /// 스낵바의 addSubView
    private func addSnackBarSubview() {
        defer {
            backgroundView.addSubview(title)
        }
        
        #if WISHBOARD_APP
        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            window.addSubview(backgroundView)
        } else {
            // 앱에서 활성화된 윈도우를 찾을 수 없는 경우 예외 처리
            print("No active window found")
            guard let window = self.window else {return}
            window.view.addSubview(backgroundView)
        }
        
        #else
        window?.view.addSubview(backgroundView)
        
        #endif
        
    }
    /// 스낵바의 제약 조건 설정
    private func setSnackBarConstraints() {
        title.snp.makeConstraints { make in
            make.centerY.centerX.equalToSuperview()
        }
        backgroundView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(SNACKBAR_HEIGHT)
            // 스낵바 길이 정적 고정
            make.leading.trailing.lessThanOrEqualToSuperview().inset(35)
            // 스낵바 길이 동적 (아랫줄 코드)
//            make.width.equalTo(title.snp.width).offset(32 * 2)
            make.height.equalTo(SNACKBAR_HEIGHT)
            make.centerX.equalToSuperview()
        }
    }
    
    /// 스낵바의 애니메이션 설정
    private func performAnimation() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5) {
                self.backgroundView.transform = CGAffineTransform(translationX: 0, y: self.TRANSLATION_Y)
            } completion: { finished in
                self.performAnimationAtApp()
            }
        }
    }
    /// 앱에서 스낵바를 실행
    private func performAnimationAtApp() {
        
        UIView.animate(withDuration: 0.5, delay: 2.5) {
            self.backgroundView.transform = .identity
        } completion: { finish in
            #if WISHBOARD_APP
            self.hide()
            
            #else
            self.hide()
            
            #endif
        }
    }
    /// 스낵바가 닫힐 때 호출되는 메서드
    private func hide() {
        isShowing = false // 스낵바가 닫혔음을 표시
        backgroundView.removeFromSuperview() // 스낵바를 화면에서 제거
    }
}
