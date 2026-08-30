//
//  ItemCollectionCell.swift
//  WishboardV2
//
//  Created by gomin on 8/3/25.
//

import Foundation
import UIKit
import Core

final class ImageCollectionCell: UICollectionViewCell {
    
    let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.image = Image.logoIcon.withTintColor(.gray_100)
        $0.backgroundColor = .black_04
        $0.clipsToBounds = true
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func configure(_ url: String?) {
        if let imgUrl = url {
            imageView.loadImage(from: imgUrl, placeholder: Image.logoIcon.withTintColor(.gray_100))
        } else {
            imageView.image = Image.logoIcon.withTintColor(.gray_100)
        }
    }
}
