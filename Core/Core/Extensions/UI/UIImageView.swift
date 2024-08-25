//
//  UIImageView.swift
//  Core
//
//  Created by gomin on 8/17/24.
//

import Foundation
import UIKit

private let imageCache = NSCache<NSString, UIImage>()

extension UIImageView {
    
    public func loadImage(from url: URL, placeholder: UIImage? = nil) {
        // 먼저 플레이스홀더를 설정합니다.
        DispatchQueue.main.async {
            if let placeholder = placeholder {
                self.image = placeholder
            }
        }
        
        let cacheKey = NSString(string: url.absoluteString)
        
        // 캐시에 이미지가 있는지 확인
        if let cachedImage = imageCache.object(forKey: cacheKey) {
            DispatchQueue.main.async {
                self.image = cachedImage
            }
            return
        }
        
        DispatchQueue.global().async {
            // URLSession을 사용하여 이미지를 비동기적으로 로드합니다.
            URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                guard let self = self else { return }
                guard let data = data, error == nil, let image = UIImage(data: data) else {
                    return
                }
                // 메인 스레드에서 이미지 설정
                DispatchQueue.main.async {
                    imageCache.setObject(image, forKey: cacheKey)  // 캐시에 이미지 저장
                    self.image = image
                }
            }.resume()
        }
    }
    
    public func loadImage(from urlString: String, placeholder: UIImage? = nil) {
        // URL이 유효한지 확인합니다.
        guard let url = URL(string: urlString) else {
            return
        }
        loadImage(from: url, placeholder: placeholder)
    }
}
