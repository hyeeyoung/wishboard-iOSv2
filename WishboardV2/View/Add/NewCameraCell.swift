//
//  NewCameraCell.swift
//  WishboardV2
//
//  Created by gomin on 8/30/25.
//


import UIKit
import Core

final class NewCameraCell: UICollectionViewCell {
    static let identifier = "NewCameraCell"
    var onTap: (() -> Void)?
    
    // Image Pick View
    
    private let cameraContainer = UIView()
    private let cameraIcon = UIImageView().then {
        $0.tintColor = .gray_200
        $0.image = Image.cameraGray
    }
    
    private let imageCountLabel = UILabel().then {
        $0.text = "0/10"
        $0.font = TypoStyle.SuitD3.font
        $0.textColor = .gray_200
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .f3f3f3
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true
        
        contentView.addSubview(cameraContainer)
        cameraContainer.addSubview(cameraIcon)
        cameraContainer.addSubview(imageCountLabel)
        
        contentView.snp.makeConstraints { make in
            make.width.height.equalTo(100)
        }
        
        cameraContainer.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        cameraIcon.snp.makeConstraints { make in
            make.width.height.equalTo(26)
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        
        imageCountLabel.snp.makeConstraints { make in
            make.top.equalTo(cameraIcon.snp.bottom).offset(6)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
    }
    required init?(coder: NSCoder) { fatalError() }
    
    public func configure(_ count: Int) {
        imageCountLabel.text = "\(count)/10"
    }
}
