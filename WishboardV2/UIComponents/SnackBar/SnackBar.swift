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
    
    static var shared = SnackBar()
    
    let SNACKBAR_HEIGHT = 48
    let SNACKBAR_INTERVAL = 34
    let TRANSLATION_Y: CGFloat
    
    var window: UIViewController?
    var type: SnackBarType?
    
    // MARK: Views

    private let snackBarLabel = PaddedLabel().then {
        $0.textColor = .white
        $0.setTypoStyleWithSingleLine(typoStyle: .SuitD2)
        $0.textAlignment = .center
        $0.numberOfLines = 0
        $0.edgeInsets = UIEdgeInsets(top: 16, left: 32, bottom: 16, right: 32)
        $0.layer.cornerRadius = 24
        $0.clipsToBounds = true
        $0.backgroundColor = .gray_700
        $0.alpha = 0.0
    }
    
    public init(in viewController: UIViewController? = nil) {
        let translationY = SNACKBAR_HEIGHT + SNACKBAR_INTERVAL
        TRANSLATION_Y = CGFloat(-translationY)
        
        #if WISHBOARD_APP
        self.setupUI()
        #else
        self.window = viewController
        self.setupUI()
        #endif
    }
    
    
    // MARK: Methods
    func show(type: SnackBarType) {
        self.type = type
        
        configure(type)
        performAnimation()
    }

    /// 스낵바 UI 설정
    private func setupUI() {
        DispatchQueue.main.async {
            self.addSubviewsAndConstraints()
        }
    }

    /// 스낵바의 문구 내용 설정
    private func configure(_ type: SnackBarType) {
        let message = type.message
        snackBarLabel.text = message
    }

    /// 스낵바의 addSubView
    private func addSubviewsAndConstraints() {
        #if WISHBOARD_APP
        let window = UIApplication.shared.keyWindow
        window?.addSubview(self.snackBarLabel)
        setConstraints()
        
        window?.layoutIfNeeded()
        
        #else
        DispatchQueue.main.async {
            self.window?.view.addSubview(self.snackBarLabel)
            self.setConstraints()
            
            self.window?.view.layoutIfNeeded()
        }
        #endif
    }

    /// 스낵바 제약 조건 설정
    private func setConstraints() {
        snackBarLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(SNACKBAR_HEIGHT) // 시작 위치를 화면 아래로 설정
            make.leading.greaterThanOrEqualToSuperview().offset(35)
            make.trailing.lessThanOrEqualToSuperview().offset(-35)
            make.height.equalTo(SNACKBAR_HEIGHT)
            make.centerX.equalToSuperview()
        }
    }

    /// 스낵바 애니메이션 실행
    private func performAnimation() {
        DispatchQueue.main.async {
            // ✅ 1) 초기 상태 유지 (이미 아래에 위치함)
            self.snackBarLabel.alpha = 0.0
            
            // ✅ 2) 올라오는 애니메이션 (0.5초)
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn, animations: {
                self.snackBarLabel.transform = CGAffineTransform(translationX: 0, y: self.TRANSLATION_Y)
                self.snackBarLabel.alpha = 1.0
                self.snackBarLabel.superview?.layoutIfNeeded()
            }) { _ in
                // ✅ 3) 2.5초 동안 유지
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    // ✅ 4) 내려가는 애니메이션 (0.5초)
                    UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
                        self.snackBarLabel.transform = .identity
                        self.snackBarLabel.alpha = 0.0
                        self.snackBarLabel.superview?.layoutIfNeeded()
                    }) { _ in
                        self.snackBarLabel.alpha = 0.0
                    }
                }
            }
        }
    }

}
