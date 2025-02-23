//
//  UIImageViewExtension.swift
//  WishboardV2
//
//  Created by gomin on 2/23/25.
//

import Foundation
import UIKit
import Kingfisher

extension UIImageView {
    
    public func loadImage(from url: URL, placeholder: UIImage? = nil) {
        
        let processor = TintImageProcessor(tint: .black_5)
        
        self.kf.setImage(
            with: url,
            placeholder: placeholder,
            options: [
                .transition(.fade(0.2)),  // 페이드 인 애니메이션 적용
                .processor(processor),    // dimmedView 추가
            ]
        )
    }
    
    public func loadImage(from urlString: String, placeholder: UIImage? = nil) {
        guard let url = URL(string: urlString) else { return }
        loadImage(from: url, placeholder: placeholder)
    }
}
