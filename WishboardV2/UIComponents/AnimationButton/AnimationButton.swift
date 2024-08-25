//
//  AnimationButton.swift
//  WishboardV2
//
//  Created by gomin on 8/24/24.
//

import Foundation
import UIKit
import Lottie
import Core

class AnimatedButton: UIButton {
    
    private var animationView = LottieAnimationView(name: "loading_horizontal_black")
    private var originalTitle: String?
    public override var isEnabled: Bool {
        didSet {
            if isEnabled {
                self.setTitleColor(.gray_700, for: .normal)
                self.backgroundColor = .green_500
            } else {
                self.setTitleColor(.gray_300, for: .normal)
                self.backgroundColor = .gray_100
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupAnimation()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupAnimation()
    }
    
    private func setupAnimation() {
        // Lottie 애니메이션 초기화
        animationView = LottieAnimationView(name: "loading_horizontal_black")
        animationView.loopMode = .loop
        animationView.isUserInteractionEnabled = false
        animationView.isHidden = true
        
        self.addSubview(animationView)
        animationView.snp.makeConstraints { make in
            make.width.equalTo(50)
            make.height.equalToSuperview()
            make.centerY.centerX.equalToSuperview()
        }
    }
    
    func startAnimation() {
        originalTitle = self.title(for: .normal) // 현재 타이틀을 저장
        self.setTitle(nil, for: .normal) // 타이틀을 제거하여 숨김 처리
        
        animationView.isHidden = false
        animationView.play()
        self.isUserInteractionEnabled = false
    }
    
    func stopAnimation() {
        animationView.stop()
        animationView.isHidden = true
        
        self.setTitle(originalTitle, for: .normal) // 원래 타이틀을 복원
        self.isUserInteractionEnabled = true
    }
}
