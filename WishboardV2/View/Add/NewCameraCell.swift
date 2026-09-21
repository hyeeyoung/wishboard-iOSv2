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
        $0.textAlignment = .center
        // 어떤 경우에도 개수 문구가 잘리지 않도록 합니다.
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .f3f3f3
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true
        
        contentView.addSubview(cameraContainer)
        cameraContainer.addSubview(cameraIcon)
        cameraContainer.addSubview(imageCountLabel)
        
        // 셀 크기는 컬렉션뷰 레이아웃이 100x100으로 정하므로,
        // contentView에 같은 크기 제약을 또 걸면 오토리사이징 제약과 충돌할 수 있습니다.
        cameraContainer.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        cameraIcon.snp.makeConstraints { make in
            make.width.height.equalTo(26)
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            // 컨테이너가 아이콘보다 좁아지지 않도록 합니다.
            make.leading.greaterThanOrEqualToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }
        
        // 가로 방향으로 컨테이너의 크기를 정해주는 제약이 없으면 레이아웃이 모호해져,
        // 개수 문구가 잘려 보일 수 있습니다. ("3/10" -> "3/...")
        imageCountLabel.snp.makeConstraints { make in
            make.top.equalTo(cameraIcon.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    
    public func configure(_ count: Int) {
        imageCountLabel.text = "\(count)/10"
    }
}
