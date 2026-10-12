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
        
        let processor = TintImageProcessor(tint: .black_05)
        
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
        guard let url = URL(string: urlString) else {
            // 주소가 잘못돼 그냥 돌아가면, 재사용된 셀에 앞 이미지가 남습니다.
            cancelImageLoad(placeholder: placeholder)
            return
        }
        loadImage(from: url, placeholder: placeholder)
    }

    /// 불러올 이미지가 없을 때 씁니다.
    ///
    /// 받아 오던 이미지가 있으면 취소합니다. 취소하지 않으면, 셀이 재사용된 뒤에
    /// 앞 아이템의 이미지가 뒤늦게 도착해 엉뚱한 셀에 그려집니다.
    public func cancelImageLoad(placeholder: UIImage? = nil) {
        kf.cancelDownloadTask()
        image = placeholder
    }
}
