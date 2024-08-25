//
//  UIImageView.swift
//  Core
//
//  Created by gomin on 8/17/24.
//

import Foundation
import UIKit

extension UIImageView {
    
    public func loadImage(from url: URL, placeholder: UIImage? = nil) {
        // 먼저 플레이스홀더를 설정합니다.
        if let placeholder = placeholder {
            self.image = placeholder
        }
        
        // URLSession을 사용하여 이미지를 비동기적으로 로드합니다.
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                return
            }
            // 메인 스레드에서 이미지 설정
            DispatchQueue.main.async {
                self.image = image
            }
        }.resume()
    }
    
    public func loadImage(from urlString: String, placeholder: UIImage? = nil) {
        // URL이 유효한지 확인합니다.
        guard let url = URL(string: urlString) else {
            return
        }
        loadImage(from: url, placeholder: placeholder)
    }
}
