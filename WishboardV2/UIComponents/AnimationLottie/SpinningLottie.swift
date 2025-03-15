//
//  SpinningLottie.swift
//  WishboardV2
//
//  Created by gomin on 3/15/25.
//

import Foundation
import Core
import UIKit
import Lottie

class SpinningLottie: UIView {
    
    private var animationView = LottieAnimationView(name: "loading_spin")
    private let blockingView = UIView() // ✅ 터치 이벤트를 막기 위한 투명한 뷰 추가

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupAnimation()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupAnimation()
    }
    
    private func setupAnimation() {
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = true // ✅ 자기 자신이 터치 이벤트를 가로채도록 설정

        // ✅ 터치 차단용 뷰 설정
        blockingView.backgroundColor = .clear
        blockingView.isUserInteractionEnabled = true // ✅ 터치를 가로챔

        // Lottie 애니메이션 초기화
        animationView = LottieAnimationView(name: "loading_spin")
        animationView.loopMode = .loop
        animationView.isUserInteractionEnabled = false
        animationView.isHidden = true
        
        // ✅ 최상위 윈도우 가져오기
        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            window.addSubview(self)
        }

        // ✅ 서브뷰 추가
        self.addSubview(blockingView)
        self.addSubview(animationView)
        
        // ✅ 오토레이아웃 설정
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        blockingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        animationView.snp.makeConstraints { make in
            make.width.height.equalTo(100)
            make.centerY.centerX.equalToSuperview()
        }
    }
    
    func startAnimation() {
        animationView.isHidden = false
        animationView.play()
        self.isUserInteractionEnabled = true // ✅ 터치 이벤트를 가로채도록 설정
    }
    
    func stopAnimation() {
        animationView.stop()
        animationView.isHidden = true
        self.isUserInteractionEnabled = false // ✅ 다시 터치 이벤트가 뒷뷰로 전달되도록 설정
        self.removeFromSuperview()
    }
}
